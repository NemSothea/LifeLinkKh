import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/match/data/dio_match_repository.dart';
import 'package:lifelink_kh/src/features/match/domain/match.dart';
import 'package:lifelink_kh/src/features/match/domain/match_response_type.dart';
import 'package:lifelink_kh/src/features/match/domain/respond_result.dart';
import 'package:lifelink_kh/src/features/request/data/dio_request_repository.dart';

/// The wire contract of `GET /matches/me` and `POST /matches/{id}/respond`.
void main() {
    late _StubAdapter adapter;
    late DioMatchRepository repository;

    setUp(() {
        adapter = _StubAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'))
            ..httpClientAdapter = adapter;
        repository = DioMatchRepository(dio, DioRequestRepository(dio));
    });

    const matchJson = '''
    {"matchId":"match-1","myBloodType":"O-","response":null,"notifiedAt":"2026-08-07T09:14:00+07:00",
     "request":{"id":"req-1","status":"OPEN","patientBloodType":"A+","unitsNeeded":1,"urgency":"URGENT",
       "hospital":{"id":"hosp-1","name":"Calmette Hospital","districtName":null},
       "alertedCount":12,"acceptedCount":0,"createdAt":"2026-08-07T09:14:00+07:00",
       "distanceKm":2.5,"requesterContact":null}}
    ''';

    group('fetchMine', () {
        test('parses myBloodType and the embedded request detail, including distanceKm', () async {
            adapter.reply(200, '[$matchJson]');

            final match = (await repository.fetchMine() as Success<List<Match>>).value.single;

            expect(match.myBloodType, BloodType.oNegative);
            expect(match.response, isNull);
            expect(match.request.distanceKm, 2.5);
            expect(match.request.hospitalName, 'Calmette Hospital');
        });

        test('a donor with no donor profile is NotFoundFailure, not shown as an error', () async {
            adapter.reply(404, '{"error":{"code":"DONOR_PROFILE_NOT_FOUND","message":"No donor profile yet."}}');

            expect(
                (await repository.fetchMine() as Failed<List<Match>>).failure,
                isA<NotFoundFailure>(),
            );
        });
    });

    group('respond', () {
        test('sends the wire value of the chosen response', () async {
            adapter.reply(200, '''
            {"matchId":"match-1","response":"DECLINED","respondedAt":"2026-08-07T09:20:00+07:00",
             "requesterContact":null}
            ''');

            await repository.respond('match-1', MatchResponseType.declined);

            expect((adapter.lastBody! as Map<String, dynamic>)['response'], 'DECLINED');
        });

        test('an acceptance carries the requester contact, unverified', () async {
            adapter.reply(200, '''
            {"matchId":"match-1","response":"ACCEPTED","respondedAt":"2026-08-07T09:20:00+07:00",
             "requesterContact":{"displayName":"Sophea","phone":"012345678","phoneVerified":false}}
            ''');

            final result = (await repository.respond('match-1', MatchResponseType.accepted)
                as Success<RespondResult>).value;

            expect(result.requesterContact!.displayName, 'Sophea');
            expect(result.requesterContact!.phoneVerified, isFalse);
        });

        test('a decline carries no contact — null, not an empty object', () async {
            adapter.reply(200, '''
            {"matchId":"match-1","response":"DECLINED","respondedAt":"2026-08-07T09:20:00+07:00",
             "requesterContact":null}
            ''');

            final result = (await repository.respond('match-1', MatchResponseType.declined)
                as Success<RespondResult>).value;

            expect(result.requesterContact, isNull);
        });

        test('answering twice is a ConflictFailure', () async {
            adapter.reply(409, '{"error":{"code":"ALREADY_RESPONDED","message":"You have already answered this."}}');

            final failure = (await repository.respond('match-1', MatchResponseType.accepted)
                as Failed<RespondResult>).failure;

            expect(
                failure,
                isA<ConflictFailure>().having((f) => f.code, 'code', 'ALREADY_RESPONDED'),
            );
        });

        test('responding to someone else\'s match is ForbiddenFailure, not sign-out', () async {
            adapter.reply(403, '{"error":{"code":"NOT_YOUR_MATCH","message":"That is not your match."}}');

            final failure = (await repository.respond('match-1', MatchResponseType.accepted)
                as Failed<RespondResult>).failure;

            expect(
                failure,
                isA<ForbiddenFailure>().having((f) => f.code, 'code', 'NOT_YOUR_MATCH'),
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
