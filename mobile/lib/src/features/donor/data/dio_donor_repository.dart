import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/blood_type.dart';
import '../domain/district.dart';
import '../domain/donor_profile.dart';
import '../domain/donor_profile_draft.dart';
import '../domain/donor_repository.dart';
import '../domain/eligibility.dart';

/// The only class in this feature that knows Dio exists.
///
/// Runs on the **intercepted** client: every call here is authenticated, and a 401 is
/// repairable by ADR 0007's silent renewal.
final class DioDonorRepository implements DonorRepository {
    const DioDonorRepository(this._dio);

    final Dio _dio;

    static const String profilePath = '/donors/me';
    static const String districtsPath = '/districts';

    @override
    Future<Result<DonorProfile?>> fetchProfile() async {
        try {
            final response = await _dio.get<Map<String, dynamic>>(profilePath);
            final body = response.data;
            if (body == null) {
                return const Failed(UnknownFailure(message: 'empty profile response'));
            }
            return Success(_profileFromJson(body));
        } on DioException catch (error) {
            // 404 is "no profile yet", which is where every donor starts. Mapping it to a
            // failure would show an error screen at the top of the happy path.
            if (error.response?.statusCode == 404) return const Success(null);
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<DonorProfile>> saveProfile(DonorProfileDraft draft) async {
        try {
            final response = await _dio.put<Map<String, dynamic>>(
                profilePath,
                data: {
                    'fullName': draft.fullName.trim(),
                    'bloodType': draft.bloodType?.wireValue,
                    'districtCode': draft.districtCode,
                    // Sent as a pair or not at all — one without the other is a 400
                    // INCOMPLETE_COORDINATES, but only when `updateCoordinates` is true. Default
                    // `false` means the server leaves whatever it already has alone (CR-MAPI-004);
                    // an edit that never touched location must not wipe stored GPS precision.
                    'latitude': draft.latitude,
                    'longitude': draft.longitude,
                    'updateCoordinates': draft.updateCoordinates,
                    // ISO date, not date-time: the server field is a LocalDate, and sending an
                    // instant would make the value depend on the device's timezone.
                    'lastDonationDate': _asIsoDate(draft.lastDonationDate),
                    'isAvailable': draft.isAvailable,
                },
            );
            final body = response.data;
            if (body == null) {
                return const Failed(UnknownFailure(message: 'empty profile response'));
            }
            return Success(_profileFromJson(body));
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    @override
    Future<Result<List<District>>> fetchDistricts() async {
        try {
            final response = await _dio.get<List<dynamic>>(districtsPath);
            final rows = response.data ?? const [];
            return Success([
                for (final row in rows)
                    if (row is Map<String, dynamic>) _districtFromJson(row),
            ]);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    static String? _asIsoDate(DateTime? value) {
        if (value == null) return null;
        final month = value.month.toString().padLeft(2, '0');
        final day = value.day.toString().padLeft(2, '0');
        return '${value.year}-$month-$day';
    }

    /// Parses a `date` (no time). `DateTime.parse` accepts the ISO date directly and yields
    /// local midnight, which is what a calendar date means here.
    static DateTime? _dateFromJson(Object? value) =>
        value is String && value.isNotEmpty ? DateTime.parse(value) : null;

    DonorProfile _profileFromJson(Map<String, dynamic> json) {
        final id = json['id'];
        final bloodType = BloodType.fromWire(json['bloodType'] as String?);
        final districtCode = json['districtCode'];
        final districtName = json['districtName'];
        final eligibility = json['eligibility'];
        if (id is! String ||
            bloodType == null ||
            districtCode is! String ||
            districtName is! Map ||
            eligibility is! Map) {
            // No defaults. A profile with a guessed blood type is a donor who gets matched to
            // the wrong patient.
            throw const FormatException('donor profile response is not usable');
        }
        return DonorProfile(
            id: id,
            fullName: json['fullName'] as String? ?? '',
            bloodType: bloodType,
            districtCode: districtCode,
            // Both labels (CR-MAPI-001), so switching locale does not need a re-fetch.
            districtNameKm: districtName['km'] as String? ?? '',
            districtNameEn: districtName['en'] as String? ?? '',
            lastDonationDate: _dateFromJson(json['lastDonationDate']),
            isAvailable: json['isAvailable'] as bool? ?? true,
            eligibility: Eligibility(
                isEligible: eligibility['isEligible'] as bool? ?? false,
                daysRemaining: eligibility['daysRemaining'] as int?,
                eligibleOn: _dateFromJson(eligibility['eligibleOn']),
            ),
        );
    }

    District _districtFromJson(Map<String, dynamic> json) {
        final code = json['code'];
        if (code is! String) {
            throw const FormatException('district row has no code');
        }
        return District(
            code: code,
            nameKm: json['nameKm'] as String? ?? '',
            nameEn: json['nameEn'] as String? ?? '',
        );
    }
}
