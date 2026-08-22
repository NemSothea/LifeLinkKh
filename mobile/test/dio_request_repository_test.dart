import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/request/data/dio_request_repository.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request.dart';
import 'package:lifelink_kh/src/features/request/domain/blood_request_draft.dart';
import 'package:lifelink_kh/src/features/request/domain/hospital.dart';
import 'package:lifelink_kh/src/features/request/domain/request_status.dart';
import 'package:lifelink_kh/src/features/request/domain/urgency.dart';

/// The wire contract of `GET /hospitals`, `POST /requests`, `GET /requests/me`,
/// `GET /requests/{id}` and `POST /requests/{id}/cancel`.
void main() {
    late _StubAdapter adapter;
    late DioRequestRepository repository;

    setUp(() {
        adapter = _StubAdapter();
        repository = DioRequestRepository(
            Dio(BaseOptions(baseUrl: 'http://test.invalid'))..httpClientAdapter = adapter,
        );
    });

    const summaryJson = '''
    {"id":"req-1","status":"OPEN","patientBloodType":"A+","unitsNeeded":1,"urgency":"URGENT",
     "hospital":{"id":"hosp-1","name":"Calmette Hospital","districtName":{"km":"ស្ទឹងមានជ័យ","en":"Stung Meanchey"}},
     "alertedCount":12,"acceptedCount":0,"createdAt":"2026-08-07T09:14:00+07:00"}
    ''';

    group('fetchHospitals', () {
        test('parses the list, with a district that may be absent', () async {
            adapter.reply(200, '''
            [{"id":"hosp-1","name":"Calmette Hospital","districtName":{"km":"ស្ទឹងមានជ័យ","en":"Stung Meanchey"}},
             {"id":"hosp-2","name":"National Blood Transfusion Center","districtName":null}]
            ''');

            final hospitals = (await repository.fetchHospitals() as Success<List<Hospital>>).value;

            expect(hospitals.map((h) => h.id), ['hosp-1', 'hosp-2']);
            expect(hospitals.first.districtLabel('en'), 'Stung Meanchey');
            expect(hospitals.last.districtLabel('en'), isNull);
        });
    });

    group('create', () {
        test('sends every RequestCreateRequest field, trimmed', () async {
            adapter.reply(201, summaryJson);

            await repository.create(
                const RequestDraft(
                    patientBloodType: BloodType.aPositive,
                    unitsNeeded: 1,
                    hospitalId: 'hosp-1',
                    urgency: Urgency.urgent,
                    contactName: '  Sophea  ',
                    contactPhone: '012345678',
                ),
            );

            final body = adapter.lastBody! as Map<String, dynamic>;
            expect(body['patientBloodType'], 'A+');
            expect(body['unitsNeeded'], 1);
            expect(body['hospitalId'], 'hosp-1');
            expect(body['urgency'], 'URGENT');
            expect(body['contactName'], 'Sophea');
            expect(body['contactPhone'], '012345678');
        });

        test('a 201 parses alertedCount, the number the waiting screen shows', () async {
            adapter.reply(201, summaryJson);

            final request = (await repository.create(
                const RequestDraft(
                    patientBloodType: BloodType.aPositive,
                    hospitalId: 'hosp-1',
                    contactName: 'Sophea',
                    contactPhone: '012345678',
                ),
            ) as Success<BloodRequest>).value;

            expect(request.alertedCount, 12);
            expect(request.acceptedCount, 0);
            expect(request.status, RequestStatus.open);
            // The list/create shape never carries these — only a matched donor's
            // detail view does.
            expect(request.distanceKm, isNull);
            expect(request.requesterContact, isNull);
        });

        test('a rate limit surfaces as RateLimitedFailure', () async {
            adapter.reply(429, '{"error":{"code":"REQUEST_RATE_LIMITED","message":"Too many requests."}}');

            final failure = (await repository.create(
                const RequestDraft(
                    patientBloodType: BloodType.aPositive,
                    hospitalId: 'hosp-1',
                    contactName: 'Sophea',
                    contactPhone: '012345678',
                ),
            ) as Failed<BloodRequest>).failure;

            expect(failure, isA<RateLimitedFailure>());
        });

        test('an unrecognised urgency in the response is refused, not guessed', () async {
            adapter.reply(201, summaryJson.replaceFirst('"URGENT"', '"SOMEDAY"'));

            expect(
                (await repository.create(
                    const RequestDraft(
                        patientBloodType: BloodType.aPositive,
                        hospitalId: 'hosp-1',
                        contactName: 'Sophea',
                        contactPhone: '012345678',
                    ),
                ) as Failed<BloodRequest>).failure,
                isA<UnknownFailure>(),
            );
        });
    });

    group('fetchMine', () {
        test('an empty table is an empty list, not a failure', () async {
            adapter.reply(200, '[]');

            expect((await repository.fetchMine()).valueOrNull, isEmpty);
        });

        test('parses both district labels on the hospital', () async {
            adapter.reply(200, '[$summaryJson]');

            final request = (await repository.fetchMine() as Success<List<BloodRequest>>)
                .value
                .single;

            expect(request.hospitalDistrictLabel('km'), 'ស្ទឹងមានជ័យ');
            expect(request.hospitalDistrictLabel('en'), 'Stung Meanchey');
        });
    });

    group('fetchDetail', () {
        test('parses distanceKm and requesterContact when both are present', () async {
            adapter.reply(200, '''
            {"id":"req-1","status":"OPEN","patientBloodType":"A+","unitsNeeded":1,"urgency":"URGENT",
             "hospital":{"id":"hosp-1","name":"Calmette Hospital","districtName":null},
             "alertedCount":12,"acceptedCount":1,"createdAt":"2026-08-07T09:14:00+07:00",
             "distanceKm":2.5,"requesterContact":{"displayName":"Sophea","phone":"012345678","phoneVerified":false}}
            ''');

            final request = (await repository.fetchDetail('req-1') as Success<BloodRequest>).value;

            expect(request.distanceKm, 2.5);
            expect(request.requesterContact!.displayName, 'Sophea');
            expect(request.requesterContact!.phoneVerified, isFalse);
        });

        test('requesterContact is null before acceptance, not an empty object', () async {
            adapter.reply(200, '''
            {"id":"req-1","status":"OPEN","patientBloodType":"A+","unitsNeeded":1,"urgency":"URGENT",
             "hospital":{"id":"hosp-1","name":"Calmette Hospital","districtName":null},
             "alertedCount":12,"acceptedCount":0,"createdAt":"2026-08-07T09:14:00+07:00",
             "distanceKm":2.5,"requesterContact":null}
            ''');

            final request = (await repository.fetchDetail('req-1') as Success<BloodRequest>).value;

            expect(request.requesterContact, isNull);
        });

        test('a 404 is NotFoundFailure — the creator/matched-donor-only rule', () async {
            adapter.reply(404, '{"error":{"code":"REQUEST_NOT_FOUND","message":"No such request."}}');

            expect(
                (await repository.fetchDetail('req-1') as Failed<BloodRequest>).failure,
                isA<NotFoundFailure>(),
            );
        });
    });

    group('cancel', () {
        test('a 403 for someone else\'s request is ForbiddenFailure, not sign-out', () async {
            adapter.reply(403, '{"error":{"code":"NOT_REQUEST_CREATOR","message":"Only the creator can close this request."}}');

            final failure = (await repository.cancel('req-1') as Failed<BloodRequest>).failure;

            expect(
                failure,
                isA<ForbiddenFailure>().having((f) => f.code, 'code', 'NOT_REQUEST_CREATOR'),
            );
        });

        test('a 409 on an already-closed request is ConflictFailure', () async {
            adapter.reply(409, '{"error":{"code":"REQUEST_ALREADY_CLOSED","message":"This request is already closed."}}');

            final failure = (await repository.cancel('req-1') as Failed<BloodRequest>).failure;

            expect(
                failure,
                isA<ConflictFailure>().having((f) => f.code, 'code', 'REQUEST_ALREADY_CLOSED'),
            );
        });
    });
}

final class _StubAdapter implements HttpClientAdapter {
    int _status = 200;
    String _body = '{}';

    Object? lastBody;

    void reply(int status, String body) {
        _status = status;
        _body = body;
    }

    @override
    Future<ResponseBody> fetch(
        RequestOptions options,
        Stream<Uint8List>? requestStream,
        Future<void>? cancelFuture,
    ) async {
        lastBody = options.data;
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
