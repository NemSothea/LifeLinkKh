// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/firestore_failure_mapper.dart';
import '../../../core/error/result.dart';
import '../../donor/domain/blood_type.dart';
import '../domain/blood_request.dart';
import '../domain/blood_request_draft.dart';
import '../domain/hospital.dart';
import '../domain/request_repository.dart';
import '../domain/request_status.dart';
import '../domain/requester_contact.dart';
import '../domain/urgency.dart';

/// `requests`, `requests/{id}/private/contact` and `hospitals` on Firestore (ADR 0009) —
/// what `/requests`, `/public/requests` and `/hospitals` were.
///
/// Posting writes the request and its contact in one batch; the `onRequestCreated`
/// Function then matches donors, pushes them and stamps `alertedCount`. [create] waits a
/// few seconds for that stamp so the detail screen it opens says how many were alerted,
/// the way the synchronous `POST /requests` did.
final class FirestoreRequestRepository implements RequestRepository {
    FirestoreRequestRepository(
        this._db, {
        required String? Function() currentUid,
        Duration matchWait = const Duration(seconds: 8),
    })  : _currentUid = currentUid,
          _matchWait = matchWait;

    final FirebaseFirestore _db;
    final String? Function() _currentUid;
    final Duration _matchWait;

    /// The hospital list, read once — five documents that change when a migration would
    /// have. Every request row is joined against it rather than re-reading a hospital each.
    Future<Map<String, Hospital>>? _hospitals;

    CollectionReference<Map<String, dynamic>> get _requests => _db.collection('requests');

    @override
    Future<Result<List<Hospital>>> fetchHospitals() async {
        try {
            final hospitals = (await _hospitalIndex()).values.toList()
                ..sort((a, b) => a.name.compareTo(b.name));
            return Success(hospitals);
        } on FirebaseException catch (error) {
            _hospitals = null;
            return Failed(failureFromFirebase(error));
        }
    }

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) async {
        final uid = _currentUid();
        if (uid == null) return const Failed(UnauthorizedFailure());
        final bloodType = draft.patientBloodType;
        final hospitalId = draft.hospitalId;
        final phone = draft.normalizedContactPhone;
        if (!draft.isComplete || bloodType == null || hospitalId == null || phone == null) {
            return const Failed(ValidationFailure(code: 'INCOMPLETE_REQUEST'));
        }
        try {
            final ref = _requests.doc();
            final batch = _db.batch()
                ..set(ref, {
                    'createdBy': uid,
                    'hospitalId': hospitalId,
                    'patientBloodType': bloodType.wireValue,
                    'unitsNeeded': draft.unitsNeeded,
                    'urgency': draft.urgency.wireValue,
                    'status': RequestStatus.open.wireValue,
                    'alertedCount': 0,
                    'acceptedCount': 0,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                })
                // Its own document: a rule cannot hide one field of a public one (ADR 0009).
                ..set(ref.collection('private').doc('contact'), {
                    'contactName': draft.contactName.trim(),
                    'contactPhone': phone,
                });
            await batch.commit();

            await _awaitMatching(ref);
            return fetchDetail(ref.id);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        }
    }

    @override
    Future<Result<List<BloodRequest>>> fetchPublicBoard() => _list(
        // OPEN only, newest first — BoardService's query. A closed request is not a call
        // for help.
        _requests.where('status', isEqualTo: RequestStatus.open.wireValue).orderBy('createdAt', descending: true),
    );

    @override
    Future<Result<List<BloodRequest>>> fetchMine() {
        final uid = _currentUid();
        if (uid == null) return Future.value(const Failed(UnauthorizedFailure()));
        return _list(_requests.where('createdBy', isEqualTo: uid).orderBy('createdAt', descending: true));
    }

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) async {
        try {
            final snapshot = await _requests.doc(requestId).get();
            final data = snapshot.data();
            if (data == null) return const Failed(NotFoundFailure());
            final request = _requestFrom(snapshot.id, data, await _hospitalIndex());
            final contact = await _contact(requestId, data);
            return Success(contact == null ? request : request.withRequesterContact(contact));
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<BloodRequest>> cancel(String requestId) async {
        try {
            // The rules allow exactly this change, by the creator, on an OPEN request; a
            // closed one comes back permission-denied, which is the old 409.
            await _requests.doc(requestId).update({
                'status': RequestStatus.cancelled.wireValue,
                'updatedAt': FieldValue.serverTimestamp(),
            });
            return fetchDetail(requestId);
        } on FirebaseException catch (error) {
            if (error.code == 'permission-denied') {
                return const Failed(ConflictFailure(code: 'REQUEST_NOT_OPEN'));
            }
            return Failed(failureFromFirebase(error));
        }
    }

    Future<Result<List<BloodRequest>>> _list(Query<Map<String, dynamic>> query) async {
        try {
            final snapshot = await query.get();
            final hospitals = await _hospitalIndex();
            return Success([for (final doc in snapshot.docs) _requestFrom(doc.id, doc.data(), hospitals)]);
        } on FirebaseException catch (error) {
            return Failed(failureFromFirebase(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    /// Waits until `onRequestCreated` has stamped `matchedAt`, or [_matchWait] passes.
    /// A timeout is not an error: the request is posted and the Function will still run —
    /// the detail screen simply opens before it has said how many donors it alerted.
    Future<void> _awaitMatching(DocumentReference<Map<String, dynamic>> ref) async {
        try {
            await ref.snapshots().firstWhere((s) => s.data()?['matchedAt'] != null).timeout(_matchWait);
        } on TimeoutException {
            // Fall through with alertedCount still 0.
        } on StateError {
            // The stream closed without the stamp; same as a timeout.
        }
    }

    /// The contact, for the creator. Anyone else is refused by the rules and gets none —
    /// a donor's view of a request comes through their match (phase 4), not this.
    Future<RequesterContact?> _contact(String requestId, Map<String, dynamic> request) async {
        if (request['createdBy'] != _currentUid()) return null;
        final data = (await _requests.doc(requestId).collection('private').doc('contact').get()).data();
        if (data == null) return null;
        return RequesterContact(
            displayName: data['contactName'] as String? ?? '',
            phone: data['contactPhone'] as String? ?? '',
            phoneVerified: false,
        );
    }

    Future<Map<String, Hospital>> _hospitalIndex() => _hospitals ??= () async {
        final districts = {
            for (final d in (await _db.collection('districts').get()).docs) d.id: d.data(),
        };
        final hospitals = await _db.collection('hospitals').get();
        return {
            for (final h in hospitals.docs)
                h.id: Hospital(
                    id: h.id,
                    name: h.data()['name'] as String? ?? '',
                    districtNameKm: districts[h.data()['districtCode']]?['nameKm'] as String?,
                    districtNameEn: districts[h.data()['districtCode']]?['nameEn'] as String?,
                ),
        };
    }();

    BloodRequest _requestFrom(String id, Map<String, dynamic> data, Map<String, Hospital> hospitals) {
        final status = RequestStatus.fromWire(data['status'] as String?);
        final bloodType = BloodType.fromWire(data['patientBloodType'] as String?);
        final urgency = Urgency.fromWire(data['urgency'] as String?);
        if (status == null || bloodType == null || urgency == null) {
            // No defaults. A request shown with a guessed blood type sends the wrong donors.
            throw const FormatException('request document is not usable');
        }
        final hospital = hospitals[data['hospitalId']];
        final createdAt = data['createdAt'];
        return BloodRequest(
            id: id,
            status: status,
            patientBloodType: bloodType,
            unitsNeeded: (data['unitsNeeded'] as num?)?.toInt() ?? 1,
            urgency: urgency,
            hospitalName: hospital?.name ?? (data['hospital'] as Map?)?['name'] as String? ?? '',
            hospitalDistrictKm: hospital?.districtNameKm,
            hospitalDistrictEn: hospital?.districtNameEn,
            alertedCount: (data['alertedCount'] as num?)?.toInt() ?? 0,
            acceptedCount: (data['acceptedCount'] as num?)?.toInt() ?? 0,
            // A just-written serverTimestamp reads back null until the server confirms it.
            createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
        );
    }
}
