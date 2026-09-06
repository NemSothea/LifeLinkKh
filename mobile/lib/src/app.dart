import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/notify/application/push_providers.dart';
import 'router/app_router.dart';
import '../l10n/app_localizations.dart';

/// A `ConsumerWidget` as of M3: the router is a provider now, because its redirect reads
/// the session.
class LifeLinkApp extends ConsumerWidget {
    const LifeLinkApp({super.key});

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

        return MaterialApp.router(
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
}
