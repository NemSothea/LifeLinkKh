// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_session_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pushSessionSyncHash() => r'1e99ba7bab0efacc27e7eba2cb8ee62da2f27e02';

/// Keeps this device's FCM registration tied to the session for as long as the app runs.
///
/// Interactive sign-in already registers (`AuthController._signInWith`). Two cases were
/// never covered, and both leave a signed-in user silently receiving nothing:
///
/// - **A restored session.** `users.fcm_token` holds one token per user, so the last
///   device to sign in owns it. Open the same account on a second device and the first
///   stops getting alerts — and reopening the first, still signed in, never took it back.
///   Registering on restore makes "the device in your hand" the one that gets the push.
/// - **A rotated token.** FCM rotates on reinstall, restore or its own schedule.
///   [PushRegistrationService.watchTokenRefreshes] existed for exactly this and nothing
///   ever subscribed to it.
///
/// Activated only by `main.dart`, like `pushArrivalsProvider`: a widget test that restores
/// a session never reaches `FirebaseMessaging` through this.
///
/// Copied from [pushSessionSync].
@ProviderFor(pushSessionSync)
final pushSessionSyncProvider = Provider<void>.internal(
  pushSessionSync,
  name: r'pushSessionSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushSessionSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushSessionSyncRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
