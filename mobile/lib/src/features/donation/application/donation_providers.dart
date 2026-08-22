import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../data/dio_donation_repository.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';
import 'donation_service.dart';

part 'donation_providers.g.dart';

@Riverpod(keepAlive: true)
DonationRepository donationRepository(DonationRepositoryRef ref) =>
    DioDonationRepository(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
DonationService donationService(DonationServiceRef ref) =>
    DonationService(ref.watch(donationRepositoryProvider));

/// The donor's own donation history, newest first.
@Riverpod(keepAlive: true)
class MyDonationsController extends _$MyDonationsController {
    @override
    Future<List<Donation>> build() async {
        final result = await ref.watch(donationServiceProvider).loadMine();
        return switch (result) {
            Success(value: final donations) => donations,
            Failed(failure: final failure) => throw failure,
        };
    }
}
