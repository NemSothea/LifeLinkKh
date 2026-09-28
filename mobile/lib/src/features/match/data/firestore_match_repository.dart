// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/api/portal_api.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/portal_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../../donor/domain/blood_type.dart';
import '../../request/data/firestore_request_repository.dart';
import '../../request/domain/requester_contact.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';

/// The donor's `matches` on Firestore (ADR 0009) — what `GET /matches/me` and
/// `POST /matches/{id}/respond` were. Still the *remote* half: `OfflineFirstMatchRepository`
/// wraps it, and the sync engine drains through it.
///
/// The answer goes to the portal's `respondToMatch` (ADR 0010), which writes it and does what
/// the trigger did; the rules refuse the write from here. Two things shape [respond]:
///
/// * **A call that gets no answer is not a refusal.** [respond] gives the portal
///   [_writeWait], then answers [NetworkFailure] — which is what makes the offline-first
///   wrapper queue the answer and show it as pending.
/// * **A replay is success, not a refusal.** The portal allows one answer per match, and the
///   wrapper's replay can deliver it twice; the same answer already there comes back as
///   `replay: true` — the `Idempotency-Key` behaviour, without a key.
final class FirestoreMatchRepository implements MatchRepository {
    FirestoreMatchRepository(
        this._db,
        this._requests, {
        required PortalApi api,
        required String? Function() currentUid,
        Duration writeWait = const Duration(seconds: 10),
    })  : _api = api,
          _currentUid = currentUid,
          _writeWait = writeWait;

    final FirebaseFirestore _db;
    final FirestoreRequestRepository _requests;
    final PortalApi _api;
    final String? Function() _currentUid;
    final Duration _writeWait;

    @override
    Future<Result<List<Match>>> fetchMine() async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        try {
            final donor = (await _db.collection('donors').doc(uid).get()).data();
            final myBloodType = BloodType.fromWire(donor?['bloodType'] as String?);
            // No profile, no matches: matching only ever reads donors with one.
            if (myBloodType == null) return const Success([]);

            final snapshot = await _db
                .collection('matches')
                // The rules only let a donor read their own; this filter is what makes the
                // query provably safe to them.
                .where('donorUid', isEqualTo: uid)
                .get();

            final matches = <Match>[];
            for (final doc in snapshot.docs) {
                final match = await _matchFrom(doc.id, doc.data(), myBloodType);
                if (match != null) matches.add(match);
            }
            // Newest alert first. Sorted here, not in the query: a match FCM never delivered
            // has a null notifiedAt, and an orderBy would hide it.
            matches.sort((a, b) => (b.notifiedAt ?? DateTime(0)).compareTo(a.notifiedAt ?? DateTime(0)));
            return Success(matches);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<RespondResult>> respond(
        String matchId,
        MatchResponseType response, {
        String? idempotencyKey,
    }) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        final ref = _db.collection('matches').doc(matchId);
        try {
            await _api
                .call('respondToMatch', {'matchId': matchId, 'response': response.wireValue})
                .timeout(_writeWait);
        } on TimeoutException {
            return const Failed(NetworkFailure());
        } on PortalCallException catch (error) {
            return Failed(failureFromPortalCall(error));
        }
        return _result(ref, response);
    }

    Future<Result<RespondResult>> _result(
        DocumentReference<Map<String, dynamic>> ref,
        MatchResponseType response,
    ) async {
        try {
            final stored = (await ref.get()).data() ?? const {};
            final respondedAt = stored['respondedAt'];
            final contact = response == MatchResponseType.accepted
                ? await _contact(stored['requestId'] as String?)
                : null;
            return Success(RespondResult(
                matchId: ref.id,
                response: response,
                respondedAt: respondedAt is Timestamp ? respondedAt.toDate() : DateTime.now(),
                requesterContact: contact,
            ));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }

    Future<Match?> _matchFrom(String id, Map<String, dynamic> data, BloodType myBloodType) async {
        final wireResponse = data['response'] as String?;
        // DEC-016: withdrawn when its donor deleted their account. Not an unanswered alert
        // — listing it as one would invite an answer to a match that is no longer anyone's.
        // Checked before the request read, which it would only waste.
        if (wireResponse == MatchResponseType.withdrawnWireValue) return null;
        final requestId = data['requestId'] as String?;
        if (requestId == null) throw const FormatException('match has no request');
        final request = await _requests.requestForMatch(
            requestId,
            distanceKm: (data['distanceKm'] as num?)?.toDouble(),
        );
        // A request deleted by hand in the console: skip the row rather than fail the list.
        if (request == null) return null;
        final response = MatchResponseType.fromWire(wireResponse);
        final notifiedAt = data['notifiedAt'];
        // RequestViews' rule: the contact only for a donor who accepted.
        final contact = response == MatchResponseType.accepted ? await _contact(requestId) : null;
        return Match(
            matchId: id,
            request: contact == null ? request : request.withRequesterContact(contact),
            myBloodType: myBloodType,
            notifiedAt: notifiedAt is Timestamp ? notifiedAt.toDate() : null,
            response: response,
        );
    }

    Future<RequesterContact?> _contact(String? requestId) async {
        if (requestId == null) return null;
        try {
            final data = (await _db.doc('requests/$requestId/private/contact').get()).data();
            if (data == null) return null;
            return RequesterContact(
                displayName: data['contactName'] as String? ?? '',
                phone: data['contactPhone'] as String? ?? '',
                phoneVerified: false,
            );
        } on FirebaseException catch (error) {
            // Accepted locally but not yet confirmed by the server: the rule that reads the
            // match cannot see the acceptance yet. No contact this time; the next load has it.
            if (error.code == 'permission-denied') return null;
            rethrow;
        }
    }
}
