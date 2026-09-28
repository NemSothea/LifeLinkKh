import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/connectivity_providers.dart';
import 'core/settings/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/donation/application/donation_providers.dart';
import 'features/match/application/match_providers.dart';
import 'features/notify/application/push_providers.dart';
import 'features/notify/domain/push_arrival.dart';
import 'features/request/application/request_providers.dart';
import 'features/match/presentation/match_detail_screen.dart';
import 'features/request/presentation/request_detail_screen.dart';
import 'features/update/presentation/update_gate.dart';
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
        // because they happened to be looking at the screen. A donor alert gets one too,
        // but only in the foreground: tapped from the tray, the donor has already seen
        // it, and what they want is the screen it is about — opened directly, no notice.
        ref.listen<AsyncValue<PushArrival>>(pushArrivalsProvider, (_, next) {
            final arrival = next.valueOrNull;
            if (arrival == null) return;
            if (ref.read(authControllerProvider).valueOrNull == null) {
                // A cold start from a tray tap: the message arrives while the keystore is
                // still being read. Keep the tap and act on it when the session is back —
                // dropped here, the alert would open the Home tab and nothing else.
                if (!arrival.foreground) _pendingTap = arrival;
                return;
            }
            _handleArrival(ref, arrival);
        });

        // The tap held above, released once the session is restored.
        ref.listen<AsyncValue<Object?>>(authControllerProvider, (_, next) {
            final tap = _pendingTap;
            if (tap == null || next.valueOrNull == null) return;
            _pendingTap = null;
            _handleArrival(ref, tap);
        });

        // Back online after a spell without a network. Every list that failed while
        // offline is still showing its "no connection" card; refetch them rather than
        // leave the donor to find the retry button on each one.
        ref.listen<AsyncValue<bool>>(isOfflineProvider, (previous, next) {
            if (previous?.valueOrNull != true || next.valueOrNull != false) return;
            if (ref.read(authControllerProvider).valueOrNull == null) return;
            ref
                ..invalidate(myMatchesControllerProvider)
                ..invalidate(myRequestsControllerProvider)
                ..invalidate(publicBoardControllerProvider)
                ..invalidate(myDonationsControllerProvider);
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
            // The update notice outermost, so it owns the status-bar inset when both
            // strips show and the offline one sits under it.
            builder: (context, child) => UpdateGate(
                child: OfflineBanner(child: child ?? const SizedBox.shrink()),
            ),
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

    /// A tray tap that landed before the session was restored (a cold start). One slot:
    /// a second tap before the first is handled simply replaces it.
    static PushArrival? _pendingTap;

    static void _handleArrival(WidgetRef ref, PushArrival arrival) {
        ref
            ..invalidate(myMatchesControllerProvider)
            ..invalidate(myRequestsControllerProvider)
            ..invalidate(requestDetailProvider);

        // Tapped from the tray (or the tap that launched the app): open the screen the
        // push is about. The person has already read the notification — a second copy of
        // it as a snackbar with a "View" button is one tap too many at 03:00.
        if (!arrival.foreground) {
            unawaited(_openForTap(ref, arrival));
            return;
        }

        // All three go to the requester and open the same screen; only the notice's
        // wording differs. An approval or rejection is news the family has been
        // waiting on since they pressed Send (DEC-015).
        final requesterNotice = switch (arrival.type) {
            PushArrival.donorAccepted => (AppLocalizations l10n) => l10n.donorAcceptedNotice,
            PushArrival.requestApproved => (AppLocalizations l10n) => l10n.requestApprovedNotice,
            PushArrival.requestRejected => (AppLocalizations l10n) => l10n.requestRejectedNotice,
            _ => null,
        };
        if (requesterNotice != null) _showRequesterNotice(ref, arrival, requesterNotice);
        if (arrival.type == PushArrival.requestAlert) _showRequestAlertNotice(ref, arrival);
    }

    /// Where a tray tap goes: a donor alert to the match it names, the requester's three
    /// to their request. A type this app does not know, or a payload without a request,
    /// goes nowhere — the refetch above has already done what it can.
    static Future<void> _openForTap(WidgetRef ref, PushArrival arrival) async {
        final requestId = arrival.requestId;
        if (requestId == null) return;
        switch (arrival.type) {
            case PushArrival.requestAlert:
                final matchId = await _matchIdFor(ref, requestId);
                if (matchId == null) return;
                _openUnlessShowing(ref, MatchDetailScreen.routeFor(matchId));
            case PushArrival.donorAccepted:
            case PushArrival.requestApproved:
            case PushArrival.requestRejected:
                _openUnlessShowing(ref, RequestDetailScreen.routeFor(requestId));
        }
    }

    /// The payload names the request, the screen wants the match: look it up in the
    /// inbox the caller has just refetched. Null when the fetch fails or the alert is
    /// for a match this donor no longer has (withdrawn, or the request closed).
    static Future<String?> _matchIdFor(WidgetRef ref, String requestId) async {
        try {
            final matches = await ref.read(myMatchesControllerProvider.future);
            return matches.where((m) => m.request.id == requestId).firstOrNull?.matchId;
        } catch (_) {
            return null;
        }
    }

    static void _showRequesterNotice(
        WidgetRef ref,
        PushArrival arrival,
        String Function(AppLocalizations) message,
    ) {
        final messenger = _messenger.currentState;
        if (messenger == null) return;
        // The messenger sits under `MaterialApp`'s `Localizations`, so its context
        // resolves the current language.
        final l10n = AppLocalizations.of(messenger.context)!;
        final requestId = arrival.requestId;
        messenger.showSnackBar(
            SnackBar(
                content: Text(message(l10n)),
                action: requestId == null
                    ? null
                    : SnackBarAction(
                        label: l10n.donorAcceptedNoticeAction,
                        onPressed: () =>
                            _openUnlessShowing(ref, RequestDetailScreen.routeFor(requestId)),
                    ),
            ),
        );
    }

    static void _showRequestAlertNotice(WidgetRef ref, PushArrival arrival) {
        final messenger = _messenger.currentState;
        if (messenger == null) return;
        final l10n = AppLocalizations.of(messenger.context)!;
        final requestId = arrival.requestId;
        messenger.showSnackBar(
            SnackBar(
                content: Text(l10n.requestAlertNotice),
                action: requestId == null
                    ? null
                    : SnackBarAction(
                        label: l10n.requestAlertNoticeAction,
                        onPressed: () async {
                            final matchId = await _matchIdFor(ref, requestId);
                            if (matchId == null) return;
                            _openUnlessShowing(ref, MatchDetailScreen.routeFor(matchId));
                        },
                    ),
            ),
        );
    }

    /// The notice's "View" can be tapped while that very screen is already on top — the
    /// family is usually watching their request when the acceptance lands, and the
    /// listener above has just refetched it. Pushing again stacks a second copy of the
    /// same screen, and back then appears to do nothing.
    static void _openUnlessShowing(WidgetRef ref, String location) {
        final router = ref.read(appRouterProvider);
        if (router.state.uri.path == location) return;
        router.push(location);
    }
}
