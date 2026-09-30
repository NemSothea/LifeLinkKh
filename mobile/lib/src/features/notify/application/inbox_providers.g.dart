// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationInboxRepositoryHash() =>
    r'0000000000000000000000000000000000000000';

/// Overridden in `main.dart` with the Firestore inbox. The default is always empty, so
/// every widget test that builds Home gets a bell with no badge and no listener.
///
/// Copied from [notificationInboxRepository].
@ProviderFor(notificationInboxRepository)
final notificationInboxRepositoryProvider =
    Provider<NotificationInboxRepository>.internal(
      notificationInboxRepository,
      name: r'notificationInboxRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationInboxRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationInboxRepositoryRef = ProviderRef<NotificationInboxRepository>;
String _$inboxHash() => r'0000000000000000000000000000000000000000';

/// The signed-in user's inbox, live. Empty signed out; re-subscribes on the next sign-in,
/// because it watches only the user's id.
///
/// Copied from [inbox].
@ProviderFor(inbox)
final inboxProvider = StreamProvider<List<AppNotification>>.internal(
  inbox,
  name: r'inboxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inboxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InboxRef = StreamProviderRef<List<AppNotification>>;
String _$unreadNotificationCountHash() =>
    r'0000000000000000000000000000000000000000';

/// The number on the bell.
///
/// Copied from [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = Provider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = ProviderRef<int>;
String _$inboxReadMarksHash() => r'0000000000000000000000000000000000000000';

/// Ids this launch has marked read, ahead of the server's answer.
///
/// Copied from [InboxReadMarks].
@ProviderFor(InboxReadMarks)
final inboxReadMarksProvider =
    NotifierProvider<InboxReadMarks, Set<String>>.internal(
      InboxReadMarks.new,
      name: r'inboxReadMarksProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inboxReadMarksHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InboxReadMarks = Notifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
