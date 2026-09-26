// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
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
/// wraps it exactly as it wrapped the Dio one.
///
/// Two Firestore behaviours shape [respond]:
///
/// * **An offline write never fails, it waits.** The SDK queues it and the Future completes
///   when the server confirms. So [respond] gives it [_writeWait], then answers
///   [NetworkFailure] — which is what makes the offline-first wrapper queue the answer and
///   show it as pending, the same as a Dio timeout did.
/// * **A replay is refused, not ignored.** The rules allow one answer per match; the SDK's
///   own queue and the wrapper's replay can both deliver it. So `permission-denied` is
///   checked against what is stored: the same answer already there is success — the
///   `Idempotency-Key` behaviour, without a key.
final class FirestoreMatchRepository implements MatchRepository {
    FirestoreMatchRepository(
        this._db,
        this._requests, {
        required String? Function() currentUid,
        Duration writeWait = const Duration(seconds: 10),
    })  : _currentUid = currentUid,
          _writeWait = writeWait;

    final FirebaseFirestore _db;
    final FirestoreRequestRepository _requests;
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
            await ref
                .update({'response': response.wireValue, 'respondedAt': FieldValue.serverTimestamp()})
                .timeout(_writeWait);
        } on TimeoutException {
            return const Failed(NetworkFailure());
        } on FirebaseException catch (error) {
            if (error.code != 'permission-denied') return Failed(failureFromFirebase(error));
            return _explainRefusal(ref, response);
        }
        return _result(ref, response);
    }

    /// Why the rules said no, read back from the match itself.
    Future<Result<RespondResult>> _explainRefusal(
        DocumentReference<Map<String, dynamic>> ref,
        MatchResponseType response,
    ) async {
        try {
            final stored = (await ref.get()).data();
            if (stored == null) return const Failed(NotFoundFailure());
            final storedResponse = MatchResponseType.fromWire(stored['response'] as String?);
            // The same answer is already there: this was a replay of one that landed.
            if (storedResponse == response) return _result(ref, response);
            if (storedResponse != null) {
                // One response, never overwritten (FR-REQUEST-004 deferred).
                return const Failed(ConflictFailure(code: 'ALREADY_RESPONDED'));
            }
            // Unanswered and still refused: the request is no longer open.
            return const Failed(ConflictFailure(code: 'REQUEST_NOT_OPEN'));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
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
        final requestId = data['requestId'] as String?;
        if (requestId == null) throw const FormatException('match has no request');
        final request = await _requests.requestForMatch(
            requestId,
            distanceKm: (data['distanceKm'] as num?)?.toDouble(),
        );
        // A request deleted by hand in the console: skip the row rather than fail the list.
        if (request == null) return null;
        final response = MatchResponseType.fromWire(data['response'] as String?);
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
