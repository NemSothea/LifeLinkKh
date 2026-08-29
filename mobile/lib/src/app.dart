import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import '../l10n/app_localizations.dart';

/// A `ConsumerWidget` as of M3: the router is a provider now, because its redirect reads
/// the session.
class LifeLinkApp extends ConsumerWidget {
    const LifeLinkApp({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
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
            // make it the real default; this line is what actually does that on mobile.
            // No in-app switch exists yet on this client (`MeTab`'s TODO) — until it
            // ships, an English speaker cannot self-select English here the way the
            // portal's `LanguageSwitcher` already lets them.
            locale: const Locale('km'),
            supportedLocales: const [Locale('km'), Locale('en')],
        );
    }
}
