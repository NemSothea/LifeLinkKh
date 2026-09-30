import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/notify/application/inbox_providers.dart';
import 'package:lifelink_kh/src/features/notify/data/firestore_notification_inbox_repository.dart';
import 'package:lifelink_kh/src/features/notify/domain/app_notification.dart';
import 'package:lifelink_kh/src/features/notify/domain/notification_inbox_repository.dart';
import 'package:lifelink_kh/src/features/notify/presentation/notification_bell.dart';
import 'package:lifelink_kh/src/features/notify/presentation/notifications_screen.dart';

import 'support/auth_fakes.dart';

/// The bell and its inbox, `users/{uid}/notifications` — filed by the portal's server
/// beside each push, read and marked read here.
final class _FakeInbox implements NotificationInboxRepository {
    final _controller = StreamController<List<AppNotification>>.broadcast();
    List<AppNotification> _entries = const [];
    final List<List<String>> markReadCalls = [];
    String? watchedUid;

    void emit(List<AppNotification> entries) {
        _entries = entries;
        _controller.add(entries);
    }

    @override
    Stream<List<AppNotification>> watch(String uid) async* {
        watchedUid = uid;
        yield _entries;
        yield* _controller.stream;
    }

    @override
    Future<void> markRead(String uid, Iterable<String> ids) async =>
        markReadCalls.add(ids.toList());
}

AppNotification _entry(String id, {String type = 'REQUEST_ALERT', DateTime? readAt}) =>
    AppNotification(
        id: id,
        type: type,
        requestId: 'r-$id',
        title: 'Urgent blood request $id',
        body: 'AB+ needed at Calmette Hospital',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        readAt: readAt,
    );

Widget _app(_FakeInbox inbox) {
    final router = GoRouter(
        routes: [
            GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                    appBar: AppBar(actions: const [NotificationBell()]),
                ),
            ),
            GoRoute(
                path: NotificationsScreen.path,
                builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
                path: '/inbox/:matchId',
                builder: (context, state) => Scaffold(
                    appBar: AppBar(),
                    body: Text('match ${state.pathParameters['matchId']}'),
                ),
            ),
            GoRoute(
                path: '/requests/:requestId',
                builder: (context, state) => Scaffold(
                    appBar: AppBar(),
                    body: Text('request ${state.pathParameters['requestId']}'),
                ),
            ),
        ],
    );
    return ProviderScope(
        overrides: [
            sessionStoreProvider.overrideWithValue(FakeSessionStore(testSession())),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            googleCredentialsProvider.overrideWithValue(FakeGoogleCredentials()),
            facebookCredentialsProvider.overrideWithValue(FakeFacebookCredentials()),
            notificationInboxRepositoryProvider.overrideWithValue(inbox),
        ],
        child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('km'), Locale('en')],
        ),
    );
}

String? _badgeText(WidgetTester tester) {
    final badge = tester.widget<Badge>(find.byKey(const Key('notification-badge')));
    if (!badge.isLabelVisible) return null;
    return (badge.label! as Text).data;
}

void main() {
    group('the bell', () {
        testWidgets('counts only unread entries, for the signed-in user', (tester) async {
            final inbox = _FakeInbox()
                ..emit([_entry('a'), _entry('b'), _entry('c', readAt: DateTime(2026))]);
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();

            expect(inbox.watchedUid, testUid);
            expect(_badgeText(tester), '2');
        });

        testWidgets('no badge with nothing unread', (tester) async {
            final inbox = _FakeInbox()..emit([_entry('a', readAt: DateTime(2026))]);
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();
            expect(_badgeText(tester), isNull);
        });

        testWidgets('a push filed while the app is open raises the count at once',
            (tester) async {
            final inbox = _FakeInbox();
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();
            expect(_badgeText(tester), isNull);

            inbox.emit([_entry('a')]);
            await tester.pumpAndSettle();
            expect(_badgeText(tester), '1');
        });

        testWidgets('ten or more reads 9+', (tester) async {
            final inbox = _FakeInbox()..emit([for (var i = 0; i < 12; i++) _entry('$i')]);
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();
            expect(_badgeText(tester), '9+');
        });
    });

    group('the list', () {
        testWidgets('opening it lists the entries and marks the unread ones read',
            (tester) async {
            final inbox = _FakeInbox()
                ..emit([_entry('a'), _entry('b', readAt: DateTime(2026))]);
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('notification-bell')));
            await tester.pumpAndSettle();

            expect(find.text('Urgent blood request a'), findsOneWidget);
            expect(find.text('Urgent blood request b'), findsOneWidget);
            // The dot stays on the one that was new, while the person reads it.
            expect(find.byKey(const Key('notification-unread-a')), findsOneWidget);
            expect(find.byKey(const Key('notification-unread-b')), findsNothing);
            expect(inbox.markReadCalls, [
                ['a'],
            ]);

            // Back on the bell: the badge is gone before the server has answered.
            await tester.pageBack();
            await tester.pumpAndSettle();
            expect(_badgeText(tester), isNull);
        });

        testWidgets('empty says what will appear there', (tester) async {
            await tester.pumpWidget(_app(_FakeInbox()));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('notification-bell')));
            await tester.pumpAndSettle();
            expect(find.text('No notifications yet'), findsOneWidget);
        });

        testWidgets("a donor alert opens the match; news about one's request opens the request",
            (tester) async {
            final inbox = _FakeInbox()
                ..emit([_entry('a'), _entry('b', type: 'DONOR_ACCEPTED')]);
            await tester.pumpWidget(_app(inbox));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('notification-bell')));
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('notification-a')));
            await tester.pumpAndSettle();
            expect(find.text('match r-a_$testUid'), findsOneWidget);

            await tester.pageBack();
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('notification-b')));
            await tester.pumpAndSettle();
            expect(find.text('request r-b'), findsOneWidget);
        });
    });

    group('FirestoreNotificationInboxRepository', () {
        late FakeFirebaseFirestore db;
        late FirestoreNotificationInboxRepository repository;

        setUp(() {
            db = FakeFirebaseFirestore();
            repository = FirestoreNotificationInboxRepository(db);
        });

        Future<void> file(String id, DateTime at, {String? title = 'Title'}) =>
            db.doc('users/u1/notifications/$id').set({
                'type': 'REQUEST_ALERT',
                'requestId': 'r1',
                'title': ?title,
                'body': 'Body',
                'createdAt': Timestamp.fromDate(at),
                'readAt': null,
            });

        test('newest first, and an entry missing its text is skipped', () async {
            await file('old', DateTime(2026, 9, 1));
            await file('new', DateTime(2026, 9, 2));
            await file('broken', DateTime(2026, 9, 3), title: null);

            final entries = await repository.watch('u1').first;
            expect(entries.map((e) => e.id), ['new', 'old']);
            expect(entries.first.isUnread, isTrue);
        });

        test('markRead stamps readAt on exactly the ids given', () async {
            await file('a', DateTime(2026, 9, 1));
            await file('b', DateTime(2026, 9, 2));
            await repository.markRead('u1', ['a']);

            expect((await db.doc('users/u1/notifications/a').get()).get('readAt'), isNotNull);
            expect((await db.doc('users/u1/notifications/b').get()).get('readAt'), isNull);
        });
    });
}
