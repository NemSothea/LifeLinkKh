// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_token_gateway.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authTokenGatewayHash() => r'5720a4c5ba4871ad34b6b2db238ed6ff7d8a5e87';

/// The seam between `core/` and the auth feature.
///
/// Defaults to `null`, which produces an unauthenticated Dio — correct for `GET /health`
/// and for any test that has no interest in sign-in. `main.dart` overrides it with the
/// real `AuthService`; a default that threw instead would make every widget test declare
/// an auth stub it does not use.
///
/// Copied from [authTokenGateway].
@ProviderFor(authTokenGateway)
final authTokenGatewayProvider = Provider<AuthTokenGateway?>.internal(
  authTokenGateway,
  name: r'authTokenGatewayProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authTokenGatewayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthTokenGatewayRef = ProviderRef<AuthTokenGateway?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
