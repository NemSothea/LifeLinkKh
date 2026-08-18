import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_service.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/donor/domain/district.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile_draft.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_repository.dart';
import 'package:lifelink_kh/src/features/donor/domain/eligibility.dart';

void main() {
    late _FakeDonorRepository repository;

    DonorService serviceUnder() => DonorService(repository);

    setUp(() => repository = _FakeDonorRepository());

    const complete = DonorProfileDraft(
        fullName: 'Nem Sothea',
        bloodType: BloodType.oNegative,
        districtCode: '1204',
    );

    group('save', () {
        test('a complete draft reaches the repository', () async {
            final result = await serviceUnder().save(complete);

            expect(result, isA<Success<DonorProfile>>());
            expect(repository.saved, isNotNull);
        });

        test('a draft with no blood type is refused without a round trip', () async {
            const draft = DonorProfileDraft(fullName: 'Nem Sothea', districtCode: '1204');

            final failure = (await serviceUnder().save(draft) as Failed<DonorProfile>).failure;

            expect(
                failure,
                isA<ValidationFailure>().having((f) => f.code, 'code', 'INCOMPLETE_DRAFT'),
            );
            expect(repository.saved, isNull, reason: 'no request was sent');
        });

        test('a draft with no district is refused', () async {
            const draft = DonorProfileDraft(
                fullName: 'Nem Sothea',
                bloodType: BloodType.oNegative,
            );

            expect(await serviceUnder().save(draft), isA<Failed<DonorProfile>>());
            expect(repository.saved, isNull);
        });

        test('a whitespace-only name is not a name', () async {
            const draft = DonorProfileDraft(
                fullName: '   ',
                bloodType: BloodType.oNegative,
                districtCode: '1204',
            );

            expect(await serviceUnder().save(draft), isA<Failed<DonorProfile>>());
        });

        test('a missing date and missing coordinates are NOT refused', () async {
            // FR-DONOR-001: a first-time donor finishes setup without entering any date, and
            // declining GPS still produces a matchable profile (ADR 0003).
            final result = await serviceUnder().save(complete);

            expect(result, isA<Success<DonorProfile>>());
            expect(repository.saved!.lastDonationDate, isNull);
            expect(repository.saved!.latitude, isNull);
        });
    });

    group('draftFrom', () {
        test('carries every editable field back into the form', () async {
            final draft = serviceUnder().draftFrom(_profile());

            expect(draft.fullName, 'Nem Sothea');
            expect(draft.bloodType, BloodType.oNegative);
            expect(draft.districtCode, '1204');
            expect(draft.lastDonationDate, DateTime(2026, 6, 14));
            expect(draft.isAvailable, isTrue);
            expect(draft.isComplete, isTrue);
        });

        test('has no coordinates, because the read model has none', () async {
            // Documented in DonorService: latent until geolocator lands at M6, and it needs a
            // decision then rather than a guess now.
            final draft = serviceUnder().draftFrom(_profile());

            expect(draft.latitude, isNull);
            expect(draft.longitude, isNull);
        });
    });

    test('loadProfile passes a missing profile through as Success(null)', () async {
        repository.profile = null;

        final result = await serviceUnder().loadProfile();

        expect(result, isA<Success<DonorProfile?>>());
        expect(result.valueOrNull, isNull);
    });

    test('loadDistricts passes the server order through untouched', () async {
        final districts = (await serviceUnder().loadDistricts()).valueOrNull!;

        expect(districts.map((d) => d.code), ['1201', '1204']);
    });
}

DonorProfile _profile() => DonorProfile(
    id: '11111111-1111-1111-1111-111111111111',
    fullName: 'Nem Sothea',
    bloodType: BloodType.oNegative,
    districtCode: '1204',
    districtNameKm: 'ទួលគោក',
    districtNameEn: 'Tuol Kouk',
    lastDonationDate: DateTime(2026, 6, 14),
    isAvailable: true,
    eligibility: Eligibility(
        isEligible: false,
        daysRemaining: 12,
        eligibleOn: DateTime(2026, 8, 9),
    ),
);

final class _FakeDonorRepository implements DonorRepository {
    DonorProfile? profile = _profile();
    DonorProfileDraft? saved;

    @override
    Future<Result<DonorProfile?>> fetchProfile() async => Success(profile);

    @override
    Future<Result<DonorProfile>> saveProfile(DonorProfileDraft draft) async {
        saved = draft;
        return Success(_profile());
    }

    @override
    Future<Result<List<District>>> fetchDistricts() async => const Success([
        District(code: '1201', nameKm: 'ចំការមន', nameEn: 'Chamkar Mon'),
        District(code: '1204', nameKm: 'ទួលគោក', nameEn: 'Tuol Kouk'),
    ]);
}
