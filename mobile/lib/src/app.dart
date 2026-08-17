import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';
import '../l10n/app_localizations.dart';

class LifeLinkApp extends StatelessWidget {
    const LifeLinkApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: appRouter,
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
