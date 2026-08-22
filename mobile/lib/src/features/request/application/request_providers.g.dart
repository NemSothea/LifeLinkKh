// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioRequestRepositoryHash() =>
    r'88f2c9633116cd219ace47a08fa110957af8ee9e';

/// Concrete, not the `RequestRepository` interface: `DioMatchRepository` reuses
/// this exact instance's `detailFromJson` to parse the request embedded in a
/// match, which is not part of the domain-facing interface below.
///
/// Copied from [dioRequestRepository].
@ProviderFor(dioRequestRepository)
final dioRequestRepositoryProvider = Provider<DioRequestRepository>.internal(
  dioRequestRepository,
  name: r'dioRequestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioRequestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRequestRepositoryRef = ProviderRef<DioRequestRepository>;
String _$requestRepositoryHash() => r'3549c6753377d1d9bb17d33b415161bfa4a0915e';

/// See also [requestRepository].
@ProviderFor(requestRepository)
final requestRepositoryProvider = Provider<RequestRepository>.internal(
  requestRepository,
  name: r'requestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RequestRepositoryRef = ProviderRef<RequestRepository>;
String _$requestServiceHash() => r'5cc78454819fa9c0ada306d977549860f3407f10';

/// See also [requestService].
@ProviderFor(requestService)
final requestServiceProvider = Provider<RequestService>.internal(
  requestService,
  name: r'requestServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requestServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RequestServiceRef = ProviderRef<RequestService>;
String _$hospitalsHash() => r'26354d582ae2562b9835802720814fbfc63f00ab';

/// The request form's hospital dropdown. `keepAlive`, same reasoning as
/// `districtsProvider`: reference data that does not change during a session.
///
/// Copied from [hospitals].
@ProviderFor(hospitals)
final hospitalsProvider = FutureProvider<List<Hospital>>.internal(
  hospitals,
  name: r'hospitalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hospitalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HospitalsRef = FutureProviderRef<List<Hospital>>;
String _$requestDetailHash() => r'b06c9c2d80af2f96b6b07ffe48a5291820ec6753';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
/// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
/// the screen opens is correct rather than stale.
///
/// Copied from [requestDetail].
@ProviderFor(requestDetail)
const requestDetailProvider = RequestDetailFamily();

/// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
/// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
/// the screen opens is correct rather than stale.
///
/// Copied from [requestDetail].
class RequestDetailFamily extends Family<AsyncValue<BloodRequest>> {
  /// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
  /// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
  /// the screen opens is correct rather than stale.
  ///
  /// Copied from [requestDetail].
  const RequestDetailFamily();

  /// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
  /// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
  /// the screen opens is correct rather than stale.
  ///
  /// Copied from [requestDetail].
  RequestDetailProvider call(String requestId) {
    return RequestDetailProvider(requestId);
  }

  @override
  RequestDetailProvider getProviderOverride(
    covariant RequestDetailProvider provider,
  ) {
    return call(provider.requestId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'requestDetailProvider';
}

/// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
/// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
/// the screen opens is correct rather than stale.
///
/// Copied from [requestDetail].
class RequestDetailProvider extends AutoDisposeFutureProvider<BloodRequest> {
  /// A single request. Not `keepAlive`: this is `GET /requests/{id}`, and
  /// `acceptedCount` on it can change as donors respond, so a fresh fetch each time
  /// the screen opens is correct rather than stale.
  ///
  /// Copied from [requestDetail].
  RequestDetailProvider(String requestId)
    : this._internal(
        (ref) => requestDetail(ref as RequestDetailRef, requestId),
        from: requestDetailProvider,
        name: r'requestDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$requestDetailHash,
        dependencies: RequestDetailFamily._dependencies,
        allTransitiveDependencies:
            RequestDetailFamily._allTransitiveDependencies,
        requestId: requestId,
      );

  RequestDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requestId,
  }) : super.internal();

  final String requestId;

  @override
  Override overrideWith(
    FutureOr<BloodRequest> Function(RequestDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RequestDetailProvider._internal(
        (ref) => create(ref as RequestDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BloodRequest> createElement() {
    return _RequestDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestDetailProvider && other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RequestDetailRef on AutoDisposeFutureProviderRef<BloodRequest> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _RequestDetailProviderElement
    extends AutoDisposeFutureProviderElement<BloodRequest>
    with RequestDetailRef {
  _RequestDetailProviderElement(super.provider);

  @override
  String get requestId => (origin as RequestDetailProvider).requestId;
}

String _$myRequestsControllerHash() =>
    r'621db222dca1520ebd8259862fcbc2d354a31671';

/// The requester's own requests, most recent first. `keepAlive` so the list
/// survives navigating into and back out of a request's detail screen.
///
/// Copied from [MyRequestsController].
@ProviderFor(MyRequestsController)
final myRequestsControllerProvider =
    AsyncNotifierProvider<MyRequestsController, List<BloodRequest>>.internal(
      MyRequestsController.new,
      name: r'myRequestsControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myRequestsControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyRequestsController = AsyncNotifier<List<BloodRequest>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
