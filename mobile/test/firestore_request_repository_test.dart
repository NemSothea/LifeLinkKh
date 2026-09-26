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

/// The document contract of `requests` (ADR 0009) — the Firestore counterpart of
/// `dio_request_repository_test.dart`. What the rules allow is `firebase/rules-tests/`;
/// what `onRequestCreated` does with it is `firebase/functions/test/`.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirestoreRequestRepository repository;

    setUp(() async {
        db = FakeFirebaseFirestore();
        uid = 'requester';
        repository = FirestoreRequestRepository(
            db,
            currentUid: () => uid,
            matchWait: const Duration(milliseconds: 200),
        );
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

    Future<void> request(String id, {String createdBy = 'requester', String status = 'OPEN', int minutesAgo = 0}) =>
        db.doc('requests/$id').set({
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
        test('writes the request and its contact as the rules expect', () async {
            final created = (await repository.create(draft) as Success<BloodRequest>).value;

            final stored = (await db.doc('requests/${created.id}').get()).data()!;
            expect(stored, containsPair('createdBy', 'requester'));
            expect(stored, containsPair('status', 'OPEN'));
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

        test('waits for onRequestCreated, then reports how many it alerted', () async {
            // Stands in for the Function: stamp the first request that appears.
            final sub = db.collection('requests').snapshots().listen((s) {
                for (final doc in s.docs) {
                    if (doc.data()['matchedAt'] == null) {
                        doc.reference.update({'matchedAt': Timestamp.now(), 'alertedCount': 4});
                    }
                }
            });
            addTearDown(sub.cancel);

            final created = (await repository.create(draft) as Success<BloodRequest>).value;
            expect(created.alertedCount, 4);
        });

        test('a Function that never answers is not an error — the request is posted', () async {
            final result = await repository.create(draft);
            expect((result as Success<BloodRequest>).value.alertedCount, 0);
        });

        test('an incomplete draft never reaches Firestore', () async {
            final result = await repository.create(draft.copyWith(contactPhone: '123'));
            expect((result as Failed<BloodRequest>).failure, isA<ValidationFailure>());
            expect((await db.collection('requests').get()).docs, isEmpty);
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

    test('cancel moves OPEN to CANCELLED', () async {
        await request('r1');
        final cancelled = (await repository.cancel('r1') as Success<BloodRequest>).value;
        expect(cancelled.status, RequestStatus.cancelled);
    });
}
