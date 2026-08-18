import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../data/dio_donor_repository.dart';
import '../domain/district.dart';
import '../domain/donor_profile.dart';
import '../domain/donor_profile_draft.dart';
import '../domain/donor_repository.dart';
import 'donor_service.dart';

part 'donor_providers.g.dart';

@Riverpod(keepAlive: true)
DonorRepository donorRepository(DonorRepositoryRef ref) =>
    DioDonorRepository(ref.watch(apiClientProvider));

@Riverpod(keepAlive: true)
DonorService donorService(DonorServiceRef ref) =>
    DonorService(ref.watch(donorRepositoryProvider));

/// The district dropdown's options.
///
/// `keepAlive` because this is reference data that does not change during a session, and
/// re-fetching it every time the location step is rebuilt would put a spinner in the middle
/// of a form.
@Riverpod(keepAlive: true)
Future<List<District>> districts(DistrictsRef ref) async {
    final result = await ref.watch(donorServiceProvider).loadDistricts();
    return switch (result) {
        Success(value: final districts) => districts,
        // Thrown, not returned: this provider's consumer is an `AsyncValue`, and the sealed
        // Failure travels as the error object so the screen can still switch on the variant.
        Failed(failure: final failure) => throw failure,
    };
}

/// The donor's own profile. `AsyncData(null)` means "no profile yet", which is where every
/// donor starts and is the state that routes into setup.
@Riverpod(keepAlive: true)
class DonorProfileController extends _$DonorProfileController {
    @override
    Future<DonorProfile?> build() async {
        final result = await ref.watch(donorServiceProvider).loadProfile();
        return switch (result) {
            Success(value: final profile) => profile,
            Failed(failure: final failure) => throw failure,
        };
    }

    /// Saves a draft and leaves the saved profile as the new state.
    ///
    /// Returns the [Result] as well as setting state, because the setup flow needs to know
    /// whether to advance to the result screen — and a screen that watches state cannot tell
    /// "saved" from "was already like that".
    Future<Result<DonorProfile>> save(DonorProfileDraft draft) async {
        state = const AsyncLoading<DonorProfile?>().copyWithPrevious(state);
        final result = await ref.read(donorServiceProvider).save(draft);
        switch (result) {
            case Success(value: final profile):
                state = AsyncData<DonorProfile?>(profile);
            case Failed(failure: final failure):
                // Keeps the previous profile visible under the error: a failed edit must not
                // make a registered donor look unregistered, which would route them into setup.
                state = AsyncError<DonorProfile?>(failure, StackTrace.current)
                    .copyWithPrevious(state);
        }
        return result;
    }

    /// The availability toggle. Reads through the current profile because the endpoint is a
    /// full replace — sending only `isAvailable` would blank the rest of the row.
    Future<Result<DonorProfile>> setAvailability(bool isAvailable) async {
        final profile = state.valueOrNull;
        if (profile == null) {
            return const Failed(
                ValidationFailure(code: 'NO_PROFILE', message: 'nothing to toggle yet'),
            );
        }
        final service = ref.read(donorServiceProvider);
        return save(service.draftFrom(profile).copyWith(isAvailable: isAvailable));
    }
}
