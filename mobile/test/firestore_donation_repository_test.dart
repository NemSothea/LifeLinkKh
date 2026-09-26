import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donation/data/firestore_donation_repository.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';

/// The document contract of `donations` (ADR 0009) — the Firestore counterpart of
/// `dio_donation_repository_test.dart`.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirestoreDonationRepository repository;

    setUp(() async {
        db = FakeFirebaseFirestore();
        uid = 'donor-1';
        repository = FirestoreDonationRepository(db, currentUid: () => uid);
        await db.doc('districts/1201').set({'nameKm': 'ដូនពេញ', 'nameEn': 'Doun Penh'});
        await db.doc('hospitals/calmette').set({'name': 'Calmette Hospital', 'districtCode': '1201'});
    });

    Future<void> donation(String id, String donorUid, DateTime on, {String? requestId}) =>
        db.doc('donations/$id').set({
            'donorUid': donorUid,
            'hospitalId': 'calmette',
            'requestId': requestId,
            'donatedOn': Timestamp.fromDate(on),
            'confirmedBy': 'staff-1',
        });

    test('the donor\'s own donations, newest first, with the hospital joined', () async {
        await donation('old', 'donor-1', DateTime(2026, 3, 1));
        await donation('new', 'donor-1', DateTime(2026, 7, 1), requestId: 'r1');
        await donation('theirs', 'donor-2', DateTime(2026, 8, 1));

        final rows = (await repository.fetchMine() as Success<List<Donation>>).value;

        expect(rows.map((d) => d.id), ['new', 'old']);
        expect(rows.first.donatedOn, DateTime(2026, 7, 1));
        expect(rows.first.hospitalName, 'Calmette Hospital');
        expect(rows.first.hospitalDistrictLabel('en'), 'Doun Penh');
        expect(rows.first.bloodRequestId, 'r1');
        expect(rows.last.bloodRequestId, isNull);
    });

    test('no donations is an empty list, not a failure', () async {
        expect((await repository.fetchMine() as Success<List<Donation>>).value, isEmpty);
    });

    test('a donation with no date is a failure, never a guessed date', () async {
        // Real Firestore's orderBy drops a document without the field, so production never
        // gets here; the in-memory fake keeps it, which is what lets this guard be tested.
        await db.doc('donations/bad').set({
            'donorUid': 'donor-1',
            'hospitalId': 'calmette',
            'donatedOn': 'yesterday',
        });
        expect(await repository.fetchMine(), isA<Failed<List<Donation>>>());
    });

    test('signed out is UnauthorizedFailure', () async {
        uid = null;
        final result = await repository.fetchMine() as Failed<List<Donation>>;
        expect(result.failure, isA<UnauthorizedFailure>());
    });
}
