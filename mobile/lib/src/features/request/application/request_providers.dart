import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/firebase/firestore_providers.dart';
import '../data/dio_request_repository.dart';
import '../data/firestore_request_repository.dart';
import '../domain/blood_request.dart';
import '../domain/blood_request_draft.dart';
import '../domain/hospital.dart';
import '../domain/request_repository.dart';
import 'request_service.dart';

part 'request_providers.g.dart';

/// Concrete, not the `RequestRepository` interface: `DioMatchRepository` reuses
/// this exact instance's `detailFromJson` to parse the request embedded in a
/// match, which is not part of the domain-facing interface below.
@Riverpod(keepAlive: true)
DioRequestRepository dioRequestRepository(DioRequestRepositoryRef ref) =>
    DioRequestRepository(ref.watch(apiClientProvider));

/// Concrete, for the same reason the Dio one above was: `FirestoreMatchRepository` reuses
/// this instance's `requestForMatch` (and its hospital cache) for the request in a match.
@Riverpod(keepAlive: true)
FirestoreRequestRepository firestoreRequestRepository(FirestoreRequestRepositoryRef ref) =>
    FirestoreRequestRepository(
        ref.watch(firestoreProvider),
        currentUid: ref.watch(currentUidProvider),
    );

/// Firestore since ADR 0009 phase 3. `dioRequestRepository` above is unused since phase 4
/// and goes with the backend in phase 6.
@Riverpod(keepAlive: true)
RequestRepository requestRepository(RequestRepositoryRef ref) =>
    ref.watch(firestoreRequestRepositoryProvider);

@Riverpod(keepAlive: true)
RequestService requestService(RequestServiceRef ref) =>
    RequestService(ref.watch(requestRepositoryProvider));

/// The request form's hospital dropdown. `keepAlive`, same reasoning as
/// `districtsProvider`: reference data that does not change during a session.
@Riverpod(keepAlive: true)
Future<List<Hospital>> hospitals(HospitalsRef ref) async {
    final result = await ref.watch(requestServiceProvider).loadHospitals();
    return switch (result) {
        Success(value: final hospitals) => hospitals,
        Failed(failure: final failure) => throw failure,
    };
}

/// Every open request in the country, newest first.
///
/// Separate from `myMatchesControllerProvider` because it answers a different question.
/// A donor between emergencies has an empty match inbox — that is the normal state, not a
/// failure — and before this provider the home screen had nothing to show them while four
/// hospitals were asking for blood. `keepAlive` so switching tabs does not refetch, and
/// the pull-to-refresh on home invalidates it explicitly.
@Riverpod(keepAlive: true)
class PublicBoardController extends _$PublicBoardController {
    @override
    Future<List<BloodRequest>> build() async {
        final result = await ref.watch(requestServiceProvider).loadPublicBoard();
        return switch (result) {
            Success(value: final requests) => requests,
            Failed(failure: final failure) => throw failure,
        };
    }
}

/// The requester's own requests, most recent first. `keepAlive` so the list
/// survives navigating into and back out of a request's detail screen.
@Riverpod(keepAlive: true)
class MyRequestsController extends _$MyRequestsController {
    @override
    Future<List<BloodRequest>> build() async {
        final result = await ref.watch(requestServiceProvider).loadMine();
        return switch (result) {
            Success(value: final requests) => requests,
            Failed(failure: final failure) => throw failure,
        };
    }

    /// Creates the request and, on success, refreshes the list so it shows up
    /// without a manual pull-to-refresh.
    Future<Result<BloodRequest>> create(RequestDraft draft) async {
        final result = await ref.read(requestServiceProvider).create(draft);
        if (result is Success<BloodRequest>) {
            ref.invalidateSelf();
        }
        return result;
    }

    Future<Result<BloodRequest>> cancel(String requestId) async {
        final result = await ref.read(requestServiceProvider).cancel(requestId);
        if (result is Success<BloodRequest>) {
            ref.invalidateSelf();
        }
        return result;
    }
}

/// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
/// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
/// the screen opens is correct rather than stale.
@riverpod
Future<BloodRequest> requestDetail(RequestDetailRef ref, String requestId) async {
    final result = await ref.watch(requestServiceProvider).loadDetail(requestId);
    return switch (result) {
        Success(value: final request) => request,
        Failed(failure: final failure) => throw failure,
    };
}
