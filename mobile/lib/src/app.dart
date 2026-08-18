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
            // Khmer first: it is the default locale (docs/po/prd.md section 5), and it is
            // what an unmatched device language falls back to.
            supportedLocales: const [Locale('km'), Locale('en')],
        );
    }
}
