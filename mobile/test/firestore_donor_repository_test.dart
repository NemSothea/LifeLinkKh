import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/location/geohash.dart';
import 'package:lifelink_kh/src/features/donor/data/firestore_donor_repository.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/donor/domain/district.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile_draft.dart';

/// The document contract of `donors/{uid}` and `districts` (ADR 0009) — the Firestore
/// counterpart of `dio_donor_repository_test.dart`. The Security Rules are tested against
/// the real emulator in `firebase/rules-tests/`; this pins the shape the rules expect.
void main() {
    late FakeFirebaseFirestore db;
    String? uid;
    late FirestoreDonorRepository repository;
    final today = DateTime(2026, 9, 26);

    setUp(() async {
        db = FakeFirebaseFirestore();
        uid = 'donor-1';
        repository = FirestoreDonorRepository(db, currentUid: () => uid, now: () => today);
        await db.doc('districts/1201').set({'nameKm': 'ដូនពេញ', 'nameEn': 'Doun Penh'});
        await db.doc('districts/1204').set({'nameKm': 'ទួលគោក', 'nameEn': 'Tuol Kouk'});
    });

    const draft = DonorProfileDraft(
        fullName: '  Nem Sothea ',
        bloodType: BloodType.aPositive,
        districtCode: '1201',
    );

    group('fetchProfile', () {
        test('no document is Success(null) — where every donor starts, not a failure', () async {
            expect((await repository.fetchProfile() as Success<DonorProfile?>).value, isNull);
        });

        test('reads the profile, both district labels, and computes eligibility', () async {
            await db.doc('donors/donor-1').set({
                'fullName': 'Nem Sothea',
                'bloodType': 'O-',
                'districtCode': '1204',
                'lastDonationDate': Timestamp.fromDate(DateTime(2026, 8, 20)),
                'isAvailable': true,
                'lat': null,
                'lng': null,
                'geohash': null,
            });

            final profile = (await repository.fetchProfile() as Success<DonorProfile?>).value!;

            expect(profile.id, 'donor-1');
            expect(profile.bloodType, BloodType.oNegative);
            expect(profile.districtLabel('km'), 'ទួលគោក');
            expect(profile.districtLabel('en'), 'Tuol Kouk');
            expect(profile.lastDonationDate, DateTime(2026, 8, 20));
            expect(profile.eligibility.isEligible, isFalse);
            expect(profile.eligibility.eligibleOn, DateTime(2026, 10, 15));
            expect(profile.eligibility.daysRemaining, 19);
        });

        test('an unknown blood type is a failure, never a guessed default', () async {
            await db.doc('donors/donor-1').set({'bloodType': 'C+', 'districtCode': '1201'});
            expect(await repository.fetchProfile(), isA<Failed<DonorProfile?>>());
        });

        test('signed out is UnauthorizedFailure, not a read of someone else', () async {
            uid = null;
            final result = await repository.fetchProfile() as Failed<DonorProfile?>;
            expect(result.failure, isA<UnauthorizedFailure>());
        });
    });

    group('saveProfile', () {
        test('writes every field the rules require, trimmed, with no GPS', () async {
            final profile = (await repository.saveProfile(draft) as Success<DonorProfile>).value;

            final stored = (await db.doc('donors/donor-1').get()).data()!;
            expect(stored.keys, containsAll(<String>[
                'fullName', 'bloodType', 'districtCode', 'lastDonationDate', 'isAvailable',
                'lat', 'lng', 'geohash', 'createdAt', 'updatedAt',
            ]));
            expect(stored['fullName'], 'Nem Sothea');
            expect(stored['bloodType'], 'A+');
            expect(stored['lastDonationDate'], isNull);
            expect(stored['lat'], isNull);
            expect(stored['geohash'], isNull);
            expect(profile.districtLabel('en'), 'Doun Penh');
            expect(profile.eligibility.isEligible, isTrue);
        });

        test('GPS is stored with its geohash, for the matching Function', () async {
            await repository.saveProfile(
                draft.copyWith(latitude: 11.5806, longitude: 104.9165),
            );
            final stored = (await db.doc('donors/donor-1').get()).data()!;
            expect(stored['lat'], 11.5806);
            expect(stored['geohash'], encodeGeohash(11.5806, 104.9165));
        });

        test('an edit that never touched location keeps the stored GPS (CR-MAPI-004)', () async {
            await repository.saveProfile(draft.copyWith(latitude: 11.5806, longitude: 104.9165));
            final createdAt = (await db.doc('donors/donor-1').get()).data()!['createdAt'];

            await repository.saveProfile(
                const DonorProfileDraft(
                    fullName: 'Nem Sothea',
                    bloodType: BloodType.aPositive,
                    districtCode: '1204',
                ),
            );

            final stored = (await db.doc('donors/donor-1').get()).data()!;
            expect(stored['districtCode'], '1204');
            expect(stored['lat'], 11.5806);
            expect(stored['geohash'], isNotNull);
            // The rules refuse an update that re-stamps createdAt.
            expect(stored['createdAt'], createdAt);
        });

        test('clearing location clears all three coordinate fields together', () async {
            await repository.saveProfile(draft.copyWith(latitude: 11.5806, longitude: 104.9165));
            await repository.saveProfile(draft.copyWith(clearCoordinates: true));
            final stored = (await db.doc('donors/donor-1').get()).data()!;
            expect([stored['lat'], stored['lng'], stored['geohash']], [null, null, null]);
        });

        test('the last-donation date is stored as local midnight, read back as the same day', () async {
            await repository.saveProfile(draft.copyWith(lastDonationDate: DateTime(2026, 9, 26, 23, 30)));
            final stored = (await db.doc('donors/donor-1').get()).data()!;
            expect((stored['lastDonationDate'] as Timestamp).toDate(), DateTime(2026, 9, 26));

            final profile = (await repository.fetchProfile() as Success<DonorProfile?>).value!;
            expect(profile.lastDonationDate, DateTime(2026, 9, 26));
            expect(profile.eligibility.daysRemaining, 56);
        });

        test('an incomplete draft is refused before it reaches Firestore', () async {
            final result = await repository.saveProfile(const DonorProfileDraft(fullName: 'X'));
            expect((result as Failed<DonorProfile>).failure, isA<ValidationFailure>());
            expect((await db.doc('donors/donor-1').get()).exists, isFalse);
        });
    });

    group('fetchDistricts', () {
        test('every district with both labels, in code order', () async {
            final districts = (await repository.fetchDistricts() as Success<List<District>>).value;
            expect(districts.map((d) => d.code), ['1201', '1204']);
            expect(districts.first.label('km'), 'ដូនពេញ');
        });
    });
}
