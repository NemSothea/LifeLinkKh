import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../donor/domain/blood_type.dart';
import '../domain/blood_request.dart';
import '../domain/blood_request_draft.dart';
import '../domain/hospital.dart';
import '../domain/request_repository.dart';
import '../domain/request_status.dart';
import '../domain/requester_contact.dart';
import '../domain/urgency.dart';

/// The only class in this feature that knows Dio exists. Runs on the intercepted
/// client, same as [DioDonorRepository] — every call here is authenticated.
final class DioRequestRepository implements RequestRepository {
    const DioRequestRepository(this._dio);

    final Dio _dio;

    static const String hospitalsPath = '/hospitals';
    static const String requestsPath = '/requests';

    @override
    Future<Result<List<Hospital>>> fetchHospitals() async {
        try {
            final response = await _dio.get<List<dynamic>>(hospitalsPath);
            final rows = response.data ?? const [];
            return Success([
                for (final row in rows)
                    if (row is Map<String, dynamic>) _hospitalFromJson(row),
            ]);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<BloodRequest>> create(RequestDraft draft) async {
        try {
            final response = await _dio.post<Map<String, dynamic>>(
                requestsPath,
                data: {
                    'patientBloodType': draft.patientBloodType?.wireValue,
                    'unitsNeeded': draft.unitsNeeded,
                    'hospitalId': draft.hospitalId,
                    'urgency': draft.urgency.wireValue,
                    'contactName': draft.contactName.trim(),
                    'contactPhone': draft.contactPhone.trim(),
                },
            );
            return _summaryResult(response.data);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<List<BloodRequest>>> fetchMine() async {
        try {
            final response = await _dio.get<List<dynamic>>('$requestsPath/me');
            final rows = response.data ?? const [];
            return Success([
                for (final row in rows)
                    if (row is Map<String, dynamic>) _summaryFromJson(row),
            ]);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<BloodRequest>> fetchDetail(String requestId) async {
        try {
            final response = await _dio.get<Map<String, dynamic>>('$requestsPath/$requestId');
            return _detailResult(response.data);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<BloodRequest>> cancel(String requestId) async {
        try {
            final response = await _dio.post<Map<String, dynamic>>(
                '$requestsPath/$requestId/cancel',
            );
            return _summaryResult(response.data);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    Result<BloodRequest> _summaryResult(Map<String, dynamic>? body) {
        if (body == null) return const Failed(UnknownFailure(message: 'empty request response'));
        return Success(_summaryFromJson(body));
    }

    Result<BloodRequest> _detailResult(Map<String, dynamic>? body) {
        if (body == null) return const Failed(UnknownFailure(message: 'empty request response'));
        return Success(detailFromJson(body));
    }

    BloodRequest _summaryFromJson(Map<String, dynamic> json) => _requestFromJson(json);

    /// Public: `DioMatchRepository` reuses this to parse the `BloodRequestDetailResponse`
    /// embedded in a `MatchResponse`, rather than writing a second parser for the same
    /// JSON shape that could drift from this one.
    BloodRequest detailFromJson(Map<String, dynamic> json) => _requestFromJson(
        json,
        distanceKm: _numberOrNull(json['distanceKm']),
        requesterContact: _contactFromJson(json['requesterContact']),
    );

    BloodRequest _requestFromJson(
        Map<String, dynamic> json, {
        double? distanceKm,
        RequesterContact? requesterContact,
    }) {
        final id = json['id'];
        final status = RequestStatus.fromWire(json['status'] as String?);
        final bloodType = BloodType.fromWire(json['patientBloodType'] as String?);
        final urgency = Urgency.fromWire(json['urgency'] as String?);
        final unitsNeeded = json['unitsNeeded'];
        final hospital = json['hospital'];
        final createdAt = json['createdAt'];
        if (id is! String ||
            status == null ||
            bloodType == null ||
            urgency == null ||
            unitsNeeded is! int ||
            hospital is! Map ||
            hospital['name'] is! String ||
            createdAt is! String) {
            // No defaults. A guessed status or urgency is a request the app shows wrong.
            throw const FormatException('request response is not usable');
        }
        final district = hospital['districtName'];
        return BloodRequest(
            id: id,
            status: status,
            patientBloodType: bloodType,
            unitsNeeded: unitsNeeded,
            urgency: urgency,
            hospitalName: hospital['name'] as String,
            hospitalDistrictKm: district is Map ? district['km'] as String? : null,
            hospitalDistrictEn: district is Map ? district['en'] as String? : null,
            alertedCount: json['alertedCount'] as int? ?? 0,
            acceptedCount: json['acceptedCount'] as int? ?? 0,
            createdAt: DateTime.parse(createdAt),
            distanceKm: distanceKm,
            requesterContact: requesterContact,
        );
    }

    Hospital _hospitalFromJson(Map<String, dynamic> json) {
        final id = json['id'];
        final name = json['name'];
        if (id is! String || name is! String) {
            throw const FormatException('hospital row is not usable');
        }
        final district = json['districtName'];
        return Hospital(
            id: id,
            name: name,
            districtNameKm: district is Map ? district['km'] as String? : null,
            districtNameEn: district is Map ? district['en'] as String? : null,
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

    static double? _numberOrNull(Object? value) =>
        value is num ? value.toDouble() : null;
}
