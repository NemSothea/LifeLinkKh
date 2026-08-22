// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$requestFormControllerHash() =>
    r'8346c94a2df08ddd677ff2142e87422e32e67d5e';

/// Drives the one-screen request form. `autoDispose` (the default): leaving the
/// form discards it, same as `DonorSetup` — a half-filled urgent request is not
/// something to resurface later.
///
/// Copied from [RequestFormController].
@ProviderFor(RequestFormController)
final requestFormControllerProvider =
    AutoDisposeNotifierProvider<RequestFormController, RequestDraft>.internal(
      RequestFormController.new,
      name: r'requestFormControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$requestFormControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RequestFormController = AutoDisposeNotifier<RequestDraft>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
