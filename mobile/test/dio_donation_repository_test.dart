import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donation/data/dio_donation_repository.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';

/// The wire contract of `GET /donations/me`.
void main() {
    late _StubAdapter adapter;
    late DioDonationRepository repository;

    setUp(() {
        adapter = _StubAdapter();
        repository = DioDonationRepository(
            Dio(BaseOptions(baseUrl: 'http://test.invalid'))..httpClientAdapter = adapter,
        );
    });

    group('fetchMine', () {
        test('parses both hospital district labels', () async {
            adapter.reply(200, '''
            [{"id":"d-1","donatedOn":"2026-08-22",
              "hospital":{"id":"h-1","name":"Calmette Hospital","districtName":{"km":"ដូនពេញ","en":"Doun Penh"}},
              "bloodRequestId":"req-1"}]
            ''');

            final donations = (await repository.fetchMine() as Success<List<Donation>>).value;

            expect(donations, hasLength(1));
            expect(donations.first.hospitalDistrictLabel('km'), 'ដូនពេញ');
            expect(donations.first.hospitalDistrictLabel('en'), 'Doun Penh');
            expect(donations.first.bloodRequestId, 'req-1');
        });

        test('a walk-in donation has a null bloodRequestId', () async {
            adapter.reply(200, '''
            [{"id":"d-1","donatedOn":"2026-08-22",
              "hospital":{"id":"h-1","name":"Calmette Hospital","districtName":null},
              "bloodRequestId":null}]
            ''');

            final donation = (await repository.fetchMine() as Success<List<Donation>>).value.single;

            expect(donation.bloodRequestId, isNull);
            expect(donation.hospitalDistrictLabel('en'), isNull);
        });

        test('an empty table is an empty list, not a failure', () async {
            adapter.reply(200, '[]');

            expect((await repository.fetchMine()).valueOrNull, isEmpty);
        });

        test('a 401 that survived renewal is an UnauthorizedFailure', () async {
            adapter.reply(401, '{"error":{"code":"INVALID_TOKEN","message":"Not authenticated."}}');

            expect(
                (await repository.fetchMine() as Failed<List<Donation>>).failure,
                isA<UnauthorizedFailure>(),
            );
        });

        test('a row missing donatedOn is refused, not guessed', () async {
            adapter.reply(200, '[{"id":"d-1","hospital":null,"bloodRequestId":null}]');

            expect(
                (await repository.fetchMine() as Failed<List<Donation>>).failure,
                isA<UnknownFailure>(),
            );
        });
    });
}

final class _StubAdapter implements HttpClientAdapter {
    int _status = 200;
    String _body = '{}';

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
