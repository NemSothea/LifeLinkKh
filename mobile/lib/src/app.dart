import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/match/application/match_providers.dart';
import 'features/notify/application/push_providers.dart';
import 'features/notify/domain/push_arrival.dart';
import 'features/request/application/request_providers.dart';
import 'features/request/presentation/request_detail_screen.dart';
import 'router/app_router.dart';
import '../l10n/app_localizations.dart';

/// A `ConsumerWidget` as of M3: the router is a provider now, because its redirect reads
/// the session.
class LifeLinkApp extends ConsumerWidget {
    const LifeLinkApp({super.key});

    /// For the one notice raised from outside any screen: a push arriving while the app
    /// is open, which no `Scaffold` in the tree is positioned to hear.
    static final GlobalKey<ScaffoldMessengerState> _messenger =
        GlobalKey<ScaffoldMessengerState>();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        // Changing the app's language has to reach the server, not just the widget tree.
        // `users.language` is what `RequestAlertNotifier` groups urgent-request alerts by,
        // so a donor who switches to English here and is not re-registered keeps receiving
        // Khmer pushes until their next sign-in — for the one message in this product that
        // has to be understood on sight.
        //
        // Here rather than inside `LocaleController.select` so the settings layer stays
        // free of a dependency on push, and so a change from any future source is covered
        // by the same line.
        ref.listen<Locale>(localeControllerProvider, (previous, next) {
            if (previous == null || previous == next) return;
            // Signed out there is no row to update and no valid token to send; the next
            // sign-in registers the current language anyway.
            if (ref.read(authControllerProvider).valueOrNull == null) return;
            unawaited(ref.read(pushRegistrationServiceProvider).registerThisDevice());
        });

        // A push that arrives while the app is running (FR-NOTIFY-001, FR-NOTIFY-003).
        // The cached lists are stale the moment it lands: a donor has a new alert, or a
        // requester has a new acceptance. Refetch rather than wait for a pull-to-refresh
        // nobody knows to do. Android also shows no system notification for a foreground
        // app, so an acceptance gets its own in-app notice — the family must not miss it
        // because they happened to be looking at the screen.
        ref.listen<AsyncValue<PushArrival>>(pushArrivalsProvider, (_, next) {
            final arrival = next.valueOrNull;
            if (arrival == null) return;
            if (ref.read(authControllerProvider).valueOrNull == null) return;
            ref
                ..invalidate(myMatchesControllerProvider)
                ..invalidate(myRequestsControllerProvider)
                ..invalidate(requestDetailProvider);
            if (arrival.type == PushArrival.donorAccepted) _showAcceptedNotice(ref, arrival);
        });

        // Drops the native launch screen (held in `main`) the moment the router knows
        // where this launch is going — the same "still reading the keystore" test the
        // redirect in `app_router.dart` uses. A `select` on that one bool, so this widget
        // rebuilds once when it flips, not on every session change. A no-op when nothing
        // was preserved, which is every widget test.
        final restoring = ref.watch(
            authControllerProvider.select((auth) => auth.isLoading && !auth.hasValue),
        );
        if (!restoring) FlutterNativeSplash.remove();

        return MaterialApp.router(
            scaffoldMessengerKey: _messenger,
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: ref.watch(appRouterProvider),
            localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            // Explicit, not left to device-locale resolution: without a `locale:`
            // override, Flutter's default `basicLocaleListResolution` picks the device's
            // language whenever it's in `supportedLocales` — on any English-locale phone
            // (most dev/test devices) that means English, contradicting the comment this
            // replaced, which claimed Khmer was already the default. `docs/po/prd.md`
            // section 5 and the web portal's `routing.ts` (`defaultLocale: 'km'`) both
            // make it the real default.
            //
            // The value is no longer a literal: `LocaleController` defaults to Khmer and
            // then lets `MeTab`'s toggle override it, which is the half of
            // `FR-GLOBAL-001` this client was missing — until it shipped, an English
            // speaker could not read a single screen here.
            locale: ref.watch(localeControllerProvider),
            supportedLocales: LocaleController.supported,
        );
    }

    static void _showAcceptedNotice(WidgetRef ref, PushArrival arrival) {
        final messenger = _messenger.currentState;
        if (messenger == null) return;
        // The messenger sits under `MaterialApp`'s `Localizations`, so its context
        // resolves the current language.
        final l10n = AppLocalizations.of(messenger.context)!;
        final requestId = arrival.requestId;
        messenger.showSnackBar(
            SnackBar(
                content: Text(l10n.donorAcceptedNotice),
                action: requestId == null
                    ? null
                    : SnackBarAction(
                        label: l10n.donorAcceptedNoticeAction,
                        onPressed: () => ref
                            .read(appRouterProvider)
                            .push(RequestDetailScreen.routeFor(requestId)),
                    ),
            ),
        );
    }
}
