import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/features/donation/application/donation_service.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation.dart';
import 'package:lifelink_kh/src/features/donation/domain/donation_repository.dart';

void main() {
    test('loadMine passes the server order through untouched', () async {
        final repository = _FakeDonationRepository();
        final service = DonationService(repository);

        final donations = (await service.loadMine()).valueOrNull!;

        expect(donations.map((d) => d.id), ['d-1', 'd-2']);
    });

    test('an empty history is a normal Success, not a failure', () async {
        final repository = _FakeDonationRepository()..rows = const [];
        final service = DonationService(repository);

        final result = await service.loadMine();

        expect(result, isA<Success<List<Donation>>>());
        expect(result.valueOrNull, isEmpty);
    });
}

final class _FakeDonationRepository implements DonationRepository {
    List<Donation> rows = [
        Donation(id: 'd-1', donatedOn: DateTime(2026, 8, 22), hospitalName: 'Calmette Hospital'),
        Donation(id: 'd-2', donatedOn: DateTime(2026, 6, 14), hospitalName: 'Calmette Hospital'),
    ];

    @override
    Future<Result<List<Donation>>> fetchMine() async => Success(rows);
}
