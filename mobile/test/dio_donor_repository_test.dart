import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/data/dio_donor_repository.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/donor/domain/district.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile_draft.dart';

/// The wire contract of `GET`/`PUT /donors/me` and `GET /districts`.
void main() {
    late _StubAdapter adapter;
    late DioDonorRepository repository;

    setUp(() {
        adapter = _StubAdapter();
        repository = DioDonorRepository(
            Dio(BaseOptions(baseUrl: 'http://test.invalid'))..httpClientAdapter = adapter,
        );
    });

    const profileJson = '''
    {"id":"11111111-1111-1111-1111-111111111111","fullName":"Nem Sothea","bloodType":"O-",
     "districtCode":"1204","districtName":{"km":"ទួលគោក","en":"Tuol Kouk"},
     "lastDonationDate":"2026-06-14","isAvailable":true,
     "eligibility":{"isEligible":false,"daysRemaining":12,"eligibleOn":"2026-08-09"}}
    ''';

    group('fetchProfile', () {
        test('parses the profile, both district labels, and eligibility', () async {
            adapter.reply(200, profileJson);

            final profile = (await repository.fetchProfile() as Success<DonorProfile?>).value!;

            expect(profile.bloodType, BloodType.oNegative);
            expect(profile.districtCode, '1204');
            expect(profile.districtLabel('km'), 'ទួលគោក');
            expect(profile.districtLabel('en'), 'Tuol Kouk');
            expect(profile.lastDonationDate, DateTime(2026, 6, 14));
            expect(profile.eligibility.isEligible, isFalse);
            expect(profile.eligibility.daysRemaining, 12);
            expect(profile.eligibility.eligibleOn, DateTime(2026, 8, 9));
        });

        test('404 is Success(null) — where every donor starts, not a failure', () async {
            adapter.reply(404, '{"error":{"code":"DONOR_PROFILE_NOT_FOUND","message":"No donor profile yet."}}');

            final result = await repository.fetchProfile();

            expect(result, isA<Success<DonorProfile?>>());
            expect(result.valueOrNull, isNull);
        });

        test('a never-donated profile parses with a null date', () async {
            adapter.reply(200, '''
            {"id":"1","fullName":"New Donor","bloodType":"AB+","districtCode":"1201",
             "districtName":{"km":"ចំការមន","en":"Chamkar Mon"},"lastDonationDate":null,
             "isAvailable":true,"eligibility":{"isEligible":true}}
            ''');

            final profile = (await repository.fetchProfile() as Success<DonorProfile?>).value!;

            expect(profile.lastDonationDate, isNull);
            expect(profile.eligibility.isEligible, isTrue);
            expect(profile.eligibility.daysRemaining, isNull);
        });

        test('an unrecognised blood type is refused, not guessed', () async {
            // A guessed type is a donor matched to the wrong patient.
            adapter.reply(200, '''
            {"id":"1","bloodType":"XY+","districtCode":"1201",
             "districtName":{"km":"ក","en":"K"},"isAvailable":true,
             "eligibility":{"isEligible":true}}
            ''');

            expect(
                (await repository.fetchProfile() as Failed<DonorProfile?>).failure,
                isA<UnknownFailure>(),
            );
        });

        test('a 401 that survived renewal is an UnauthorizedFailure', () async {
            adapter.reply(401, '{"error":{"code":"INVALID_TOKEN","message":"Not authenticated."}}');

            expect(
                (await repository.fetchProfile() as Failed<DonorProfile?>).failure,
                isA<UnauthorizedFailure>(),
            );
        });
    });

    group('saveProfile', () {
        test('sends an ISO date, no time — the server field is a LocalDate', () async {
            adapter.reply(200, profileJson);

            await repository.saveProfile(
                DonorProfileDraft(
                    fullName: '  Nem Sothea  ',
                    bloodType: BloodType.oNegative,
                    districtCode: '1204',
                    lastDonationDate: DateTime(2026, 6, 14, 23, 30),
                ),
            );

            final body = adapter.lastBody! as Map<String, dynamic>;
            // 23:30 local must not become the 15th in UTC.
            expect(body['lastDonationDate'], '2026-06-14');
            expect(body['fullName'], 'Nem Sothea', reason: 'trimmed');
            expect(body['bloodType'], 'O-');
            expect(body['districtCode'], '1204');
        });

        test('never sends a userId — identity comes from the JWT', () async {
            adapter.reply(200, profileJson);

            await repository.saveProfile(
                const DonorProfileDraft(
                    fullName: 'Nem Sothea',
                    bloodType: BloodType.oNegative,
                    districtCode: '1204',
                ),
            );

            final body = adapter.lastBody! as Map<String, dynamic>;
            expect(body.keys, isNot(contains('userId')));
            expect(body.keys, isNot(contains('id')));
            // Struck from FR-DONOR-001 on 2026-08-17: unverified since ADR 0002, and the app
            // never reads it.
            expect(body.keys, isNot(contains('phone')));
        });

        test('a never-donated draft sends a null date rather than omitting it', () async {
            adapter.reply(200, profileJson);

            await repository.saveProfile(
                const DonorProfileDraft(
                    fullName: 'New Donor',
                    bloodType: BloodType.abPositive,
                    districtCode: '1201',
                ),
            );

            final body = adapter.lastBody! as Map<String, dynamic>;
            // Explicit null, so an edit that clears the date actually clears it server-side.
            expect(body.containsKey('lastDonationDate'), isTrue);
            expect(body['lastDonationDate'], isNull);
            expect(body['latitude'], isNull);
            expect(body['longitude'], isNull);
            // CR-MAPI-004 default: a draft that never touched location must not tell the
            // server to apply (and thus clear) these nulls.
            expect(body['updateCoordinates'], isFalse);
        });

        test('a fresh GPS fix sends updateCoordinates so the server actually applies it', () async {
            adapter.reply(200, profileJson);

            await repository.saveProfile(
                const DonorProfileDraft(
                    fullName: 'Nem Sothea',
                    bloodType: BloodType.oNegative,
                    districtCode: '1204',
                    latitude: 11.55,
                    longitude: 104.92,
                    updateCoordinates: true,
                ),
            );

            final body = adapter.lastBody! as Map<String, dynamic>;
            expect(body['latitude'], 11.55);
            expect(body['longitude'], 104.92);
            expect(body['updateCoordinates'], isTrue);
        });

        test('an unknown district keeps the server code for the form to point at', () async {
            adapter.reply(422, '{"error":{"code":"UNKNOWN_DISTRICT","message":"That district is not valid."}}');

            final failure = (await repository.saveProfile(
                const DonorProfileDraft(
                    fullName: 'Nem Sothea',
                    bloodType: BloodType.oNegative,
                    districtCode: '9999',
                ),
            ) as Failed<DonorProfile>).failure;

            expect(
                failure,
                isA<ValidationFailure>().having((f) => f.code, 'code', 'UNKNOWN_DISTRICT'),
            );
        });

        test('a future donation date surfaces its own code', () async {
            adapter.reply(422, '{"error":{"code":"LAST_DONATION_IN_FUTURE","message":"The last donation date cannot be in the future."}}');

            final failure = (await repository.saveProfile(
                DonorProfileDraft(
                    fullName: 'Nem Sothea',
                    bloodType: BloodType.oNegative,
                    districtCode: '1204',
                    lastDonationDate: DateTime(2030, 1, 1),
                ),
            ) as Failed<DonorProfile>).failure;

            expect(
                failure,
                isA<ValidationFailure>()
                    .having((f) => f.code, 'code', 'LAST_DONATION_IN_FUTURE'),
            );
        });
    });

    group('fetchDistricts', () {
        test('parses the list and preserves the server order', () async {
            // Khmer-alphabetical, sorted server-side. The client must not re-sort: it would
            // need Khmer collation on the device and could disagree with the web portal.
            adapter.reply(200, '''
            [{"code":"1201","nameKm":"ចំការមន","nameEn":"Chamkar Mon"},
             {"code":"1204","nameKm":"ទួលគោក","nameEn":"Tuol Kouk"}]
            ''');

            final districts =
                (await repository.fetchDistricts() as Success<List<District>>).value;

            expect(districts.map((d) => d.code), ['1201', '1204']);
            expect(districts.first.label('km'), 'ចំការមន');
            expect(districts.first.label('en'), 'Chamkar Mon');
        });

        test('an empty table is an empty list, not a failure', () async {
            adapter.reply(200, '[]');

            expect((await repository.fetchDistricts()).valueOrNull, isEmpty);
        });

        test('an unreachable backend is a NetworkFailure', () async {
            adapter.failWith(DioExceptionType.connectionError);

            expect(
                (await repository.fetchDistricts() as Failed<List<District>>).failure,
                isA<NetworkFailure>(),
            );
        });
    });
}

final class _StubAdapter implements HttpClientAdapter {
    int _status = 200;
    String _body = '{}';
    DioExceptionType? _transportFailure;

    Object? lastBody;

    void reply(int status, String body) {
        _status = status;
        _body = body;
        _transportFailure = null;
    }

    void failWith(DioExceptionType type) => _transportFailure = type;

    @override
    Future<ResponseBody> fetch(
        RequestOptions options,
        Stream<Uint8List>? requestStream,
        Future<void>? cancelFuture,
    ) async {
        lastBody = options.data;
        final failure = _transportFailure;
        if (failure != null) {
            throw DioException(requestOptions: options, type: failure);
        }
        return ResponseBody.fromString(
            _body,
            _status,
            headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
            },
        );
    }

    @override
    void close({bool force = false}) {}
}
