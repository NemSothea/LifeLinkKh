import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/request/data/firestore_request_repository.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';
import 'package:lifelink_kh/src/core/api/portal_api.dart';

import 'support/portal_api_fakes.dart';

/// The document contract of `requests` (ADR 0009) — the Firestore counterpart of
/// `dio_request_repository_test.dart`. What the rules allow is `firebase/rules-tests/`;
/// what the portal's `createRequest` writes is `frontend/test/server/` (ADR 0010). Here the
/// portal is a fake that writes what the real one would, so the read-back is exercised.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FakePortalApi portal;
    late FirestoreRequestRepository repository;

    setUp(() async {
        db = FakeFirebaseFirestore();
        uid = 'requester';
        portal = FakePortalApi((name, data) async {
            final fields = data! as Map;
            final ref = db.collection('requests').doc();
            await ref.set({
                'createdBy': uid,
                'hospitalId': fields['hospitalId'],
                'hospital': {'name': 'Calmette Hospital', 'districtCode': '1202'},
                'patientBloodType': fields['patientBloodType'],
                'unitsNeeded': fields['unitsNeeded'],
                'urgency': fields['urgency'],
                'status': 'PENDING',
                'alertedCount': 0,
                'acceptedCount': 0,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
            });
            await ref.collection('private').doc('contact').set({
                'contactName': fields['contactName'],
                'contactPhone': fields['contactPhone'],
            });
            return {'requestId': ref.id, 'status': 'PENDING'};
        });
        repository = FirestoreRequestRepository(db, api: portal, currentUid: () => uid);
        await db.doc('districts/1202').set({'nameKm': 'ចំការមន', 'nameEn': 'Chamkar Mon'});
        await db.doc('hospitals/calmette').set({'name': 'Calmette Hospital', 'districtCode': '1202'});
        await db.doc('hospitals/kossamak').set({'name': 'Preah Kossamak Hospital', 'districtCode': '1202'});
    });

    const draft = RequestDraft(
        patientBloodType: BloodType.abPositive,
        unitsNeeded: 2,
        hospitalId: 'calmette',
        urgency: Urgency.critical,
        contactName: ' Chea Srey ',
        contactPhone: '012 345 678',
    );

    Future<void> request(
        String id, {
        String createdBy = 'requester',
        String status = 'OPEN',
        int minutesAgo = 0,
        Map<String, Object?> extra = const {},
    }) =>
        db.doc('requests/$id').set({
            ...extra,
            'createdBy': createdBy,
            'hospitalId': 'calmette',
            'patientBloodType': 'O-',
            'unitsNeeded': 1,
            'urgency': 'URGENT',
            'status': status,
            'alertedCount': 3,
            'acceptedCount': 1,
            'createdAt': Timestamp.fromDate(DateTime(2026, 9, 26, 10).subtract(Duration(minutes: minutesAgo))),
        });

    test('hospitals, sorted by name, with their district', () async {
        final hospitals = (await repository.fetchHospitals() as Success<List<Hospital>>).value;
        expect(hospitals.map((h) => h.name), ['Calmette Hospital', 'Preah Kossamak Hospital']);
        expect(hospitals.first.districtLabel('en'), 'Chamkar Mon');
    });

    group('create', () {
        test('sends the draft to the portal\'s createRequest, normalised, and reads the result back', () async {
            final created = (await repository.create(draft) as Success<BloodRequest>).value;

            expect(portal.calls.single.name, 'createRequest');
            expect(portal.calls.single.data, {
                'hospitalId': 'calmette', 'patientBloodType': 'AB+', 'unitsNeeded': 2, 'urgency': 'CRITICAL',
                'contactName': 'Chea Srey', 'contactPhone': '+85512345678',
            });
            final stored = (await db.doc('requests/${created.id}').get()).data()!;
            expect(stored, containsPair('createdBy', 'requester'));
            // DEC-015: never OPEN on create — the rules refuse it, an admin opens it.
            expect(stored, containsPair('status', 'PENDING'));
            expect(stored, containsPair('patientBloodType', 'AB+'));
            expect(stored, containsPair('urgency', 'CRITICAL'));
            expect(stored['alertedCount'], 0);
            // Nothing private on the public document.
            expect(stored.keys, isNot(contains('contactPhone')));

            final contact = (await db.doc('requests/${created.id}/private/contact').get()).data()!;
            expect(contact, {'contactName': 'Chea Srey', 'contactPhone': '+85512345678'});
        });

        test('the creator sees their own contact on the result', () async {
            final created = (await repository.create(draft) as Success<BloodRequest>).value;
            expect(created.requesterContact?.phone, '+85512345678');
            expect(created.hospitalName, 'Calmette Hospital');
        });

        test('returns the request as PENDING straight away, with nobody alerted yet', () async {
            // Matching runs only after an admin approves (DEC-015), so there is nothing to
            // wait for — a create that waited for `matchedAt` would stall every time.
            final created = (await repository.create(draft) as Success<BloodRequest>).value;
            expect(created.status, RequestStatus.pending);
            expect(created.alertedCount, 0);
            expect(created.rejectReason, isNull);
        });

        test('an incomplete draft never reaches the portal', () async {
            final result = await repository.create(draft.copyWith(contactPhone: '123'));
            expect((result as Failed<BloodRequest>).failure, isA<ValidationFailure>());
            expect(portal.calls, isEmpty);
        });

        test('the portal\'s refusals become the failures the form knows', () async {
            portal.handler = (_, _) async => throw const PortalCallException(
                code: 'resource-exhausted', details: {'code': 'RATE_LIMITED'},
            );
            expect(((await repository.create(draft)) as Failed<BloodRequest>).failure, isA<RateLimitedFailure>());

            portal.handler = (_, _) async => throw const PortalCallException(
                code: 'invalid-argument', details: {'code': 'INVALID_REQUEST'},
            );
            expect(
                ((await repository.create(draft)) as Failed<BloodRequest>).failure,
                isA<ValidationFailure>().having((f) => f.code, 'code', 'INVALID_REQUEST'),
            );

            portal.handler = (_, _) async => throw const PortalCallException(code: 'unavailable');
            expect(((await repository.create(draft)) as Failed<BloodRequest>).failure, isA<NetworkFailure>());
        });

        test('signed out is UnauthorizedFailure', () async {
            uid = null;
            expect(((await repository.create(draft)) as Failed<BloodRequest>).failure, isA<UnauthorizedFailure>());
        });
    });

    test('the board is OPEN requests only, newest first', () async {
        await request('old', minutesAgo: 30);
        await request('new');
        await request('done', status: 'FULFILLED');
        await request('waiting', status: 'PENDING');
        await request('refused', status: 'REJECTED', extra: {'rejectReason': 'Duplicate'});
        final board = (await repository.fetchPublicBoard() as Success<List<BloodRequest>>).value;
        expect(board.map((r) => r.id), ['new', 'old']);
        expect(board.first.alertedCount, 3);
        // The board never carries a contact, even for the creator.
        expect(board.first.requesterContact, isNull);
    });

    test('mine is my requests only, any status', () async {
        await request('mine');
        await request('closed', status: 'CANCELLED', minutesAgo: 5);
        await request('theirs', createdBy: 'someone-else');
        final mine = (await repository.fetchMine() as Success<List<BloodRequest>>).value;
        expect(mine.map((r) => r.id), ['mine', 'closed']);
    });

    test('a request I did not create shows no contact', () async {
        await request('theirs', createdBy: 'someone-else');
        await db.doc('requests/theirs/private/contact').set({'contactName': 'X', 'contactPhone': '+85512345678'});
        final detail = (await repository.fetchDetail('theirs') as Success<BloodRequest>).value;
        expect(detail.requesterContact, isNull);
    });

    test('an unknown request is NotFoundFailure', () async {
        expect(((await repository.fetchDetail('nope')) as Failed<BloodRequest>).failure, isA<NotFoundFailure>());
    });

    test('a rejected request carries the admin\'s reason', () async {
        await request('refused', status: 'REJECTED', extra: {'rejectReason': 'Hospital could not confirm'});
        final detail = (await repository.fetchDetail('refused') as Success<BloodRequest>).value;
        expect(detail.status, RequestStatus.rejected);
        expect(detail.rejectReason, 'Hospital could not confirm');
    });

    test('cancel moves PENDING to CANCELLED', () async {
        await request('r0', status: 'PENDING');
        final cancelled = (await repository.cancel('r0') as Success<BloodRequest>).value;
        expect(cancelled.status, RequestStatus.cancelled);
    });

    test('cancel moves OPEN to CANCELLED', () async {
        await request('r1');
        final cancelled = (await repository.cancel('r1') as Success<BloodRequest>).value;
        expect(cancelled.status, RequestStatus.cancelled);
    });
}
