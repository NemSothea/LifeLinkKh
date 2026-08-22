import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';

/// The only class in this feature that knows Dio exists.
final class DioDonationRepository implements DonationRepository {
    const DioDonationRepository(this._dio);

    final Dio _dio;

    static const String path = '/donations/me';

    @override
    Future<Result<List<Donation>>> fetchMine() async {
        try {
            final response = await _dio.get<List<dynamic>>(path);
            final rows = response.data ?? const [];
            return Success([
                for (final row in rows)
                    if (row is Map<String, dynamic>) _donationFromJson(row),
            ]);
        } on DioException catch (error) {
            return Failed(failureFromDio(error));
        } on FormatException catch (error) {
            return Failed(UnknownFailure(message: error.message));
        }
    }

    Donation _donationFromJson(Map<String, dynamic> json) {
        final id = json['id'];
        final donatedOn = json['donatedOn'];
        if (id is! String || donatedOn is! String) {
            // No defaults. A donation with a guessed date is the 56-day cooldown lying.
            throw const FormatException('donation response is not usable');
        }
        final hospital = json['hospital'];
        final district = hospital is Map ? hospital['districtName'] : null;
        return Donation(
            id: id,
            donatedOn: DateTime.parse(donatedOn),
            hospitalName: hospital is Map ? hospital['name'] as String? : null,
            hospitalDistrictKm: district is Map ? district['km'] as String? : null,
            hospitalDistrictEn: district is Map ? district['en'] as String? : null,
            bloodRequestId: json['bloodRequestId'] as String?,
        );
    }
}
