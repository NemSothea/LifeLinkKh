// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'4963ca786eb54685cef6453544040c7567e77c0f';

/// The Firestore instance every repository reads and writes (ADR 0009).
///
/// A provider rather than `FirebaseFirestore.instance` at each call site, so a test
/// overrides it with `FakeFirebaseFirestore` and never reaches a platform channel.
///
/// Copied from [firestore].
@ProviderFor(firestore)
final firestoreProvider = Provider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = ProviderRef<FirebaseFirestore>;
String _$currentUidHash() => r'3c3c92c257b1ee3ebedcd3d3bfef13c86f9541c9';

/// The signed-in Firebase user's uid, read at call time.
///
/// A function, not a value: the user signs in and out while the repositories live, and
/// a uid captured at construction would write one donor's profile into another's
/// document. The Security Rules would refuse that write — this makes it unaskable.
///
/// Copied from [currentUid].
@ProviderFor(currentUid)
final currentUidProvider = Provider<String? Function()>.internal(
  currentUid,
  name: r'currentUidProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUidHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUidRef = ProviderRef<String? Function()>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
