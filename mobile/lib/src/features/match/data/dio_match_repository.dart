import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../donor/domain/blood_type.dart';
import '../../request/domain/requester_contact.dart';
import '../../request/data/dio_request_repository.dart' show DioRequestRepository;
import '../domain/match.dart';
import '../domain/match_repository.dart';
import '../domain/match_response_type.dart';
import '../domain/respond_result.dart';

/// The only class in this feature that knows Dio exists.
final class DioMatchRepository implements MatchRepository {
    const DioMatchRepository(this._dio, this._requests);

    final Dio _dio;

    /// Reused for the one thing it already knows how to do correctly: turn the
    /// `BloodRequestDetailResponse` embedded in a match into a [BloodRequest]. Two
    /// parsers for the same JSON shape would drift; there is exactly one.
    final DioRequestRepository _requests;

    static const String matchesPath = '/matches';

    @override
    Future<Result<List<Match>>> fetchMine() async {
        try {
            final response = await _dio.get<List<dynamic>>('$matchesPath/me');
            final rows = response.data ?? const [];
            return Success([
                for (final row in rows)
                    if (row is Map<String, dynamic>) _matchFromJson(row),
            ]);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<RespondResult>> respond(String matchId, MatchResponseType response) async {
        try {
            final result = await _dio.post<Map<String, dynamic>>(
                '$matchesPath/$matchId/respond',
                data: {'response': response.wireValue},
            );
            final body = result.data;
            if (body == null) {
                return const Failed(UnknownFailure(message: 'empty respond response'));
            }
            return Success(_respondResultFromJson(body));
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    Match _matchFromJson(Map<String, dynamic> json) {
        final matchId = json['matchId'];
        final request = json['request'];
        final myBloodType = BloodType.fromWire(json['myBloodType'] as String?);
        if (matchId is! String || request is! Map<String, dynamic> || myBloodType == null) {
            throw const FormatException('match response is not usable');
        }
        return Match(
            matchId: matchId,
            request: _requests.detailFromJson(request),
            myBloodType: myBloodType,
            notifiedAt: _dateTimeOrNull(json['notifiedAt']),
            response: MatchResponseType.fromWire(json['response'] as String?),
        );
    }

    RespondResult _respondResultFromJson(Map<String, dynamic> json) {
        final matchId = json['matchId'];
        final response = MatchResponseType.fromWire(json['response'] as String?);
        final respondedAt = json['respondedAt'];
        if (matchId is! String || response == null || respondedAt is! String) {
            throw const FormatException('respond response is not usable');
        }
        return RespondResult(
            matchId: matchId,
            response: response,
            respondedAt: DateTime.parse(respondedAt),
            requesterContact: _contactFromJson(json['requesterContact']),
        );
    }

    static RequesterContact? _contactFromJson(Object? value) {
        if (value is! Map) return null;
        final displayName = value['displayName'];
        final phone = value['phone'];
        if (displayName is! String || phone is! String) {
            throw const FormatException('requester contact is not usable');
        }
        return RequesterContact(
            displayName: displayName,
            phone: phone,
            phoneVerified: value['phoneVerified'] as bool? ?? false,
        );
    }

    static DateTime? _dateTimeOrNull(Object? value) =>
        value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
