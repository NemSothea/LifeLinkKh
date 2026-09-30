import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'brand_badge.dart';

/// What a cold start shows while the saved sign-in is read back: the native launch
/// screen's badge, in the same place on the same colour, with a spinner under it.
///
/// The native splash is a still picture and cannot say "working on it". This takes over
/// from it at Flutter's first frame, so the hand-off is the same pixels plus the one
/// thing the picture could not show — without it a slow keystore read or a cold Firebase
/// start looked like a frozen app.
class LaunchSplash extends StatelessWidget {
    const LaunchSplash({super.key});

    /// The badge's size on screen, matched to the native splash it takes over from.
    /// Android 12+ ignores the splash art and draws the launcher icon itself, in a
    /// 160 dp circle the app cannot resize — measured on the API 36 emulator, the
    /// Flutter badge at its own 104 dp visibly shrank at the hand-off. iOS (and Android
    /// before 12) show the art rendered from [BrandBadge] at its own size.
    static double badgeDiameter(TargetPlatform platform) =>
        platform == TargetPlatform.android ? 160 : BrandBadge.size;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final badge = badgeDiameter(defaultTargetPlatform);
        return Scaffold(
            key: const Key('launch-splash'),
            // Expanded to the whole screen first: a bare Stack shrinks to its largest
            // child and would sit the badge in the top-left corner.
            body: SizedBox.expand(
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                        // Centred alone, exactly as the native splash centres its icon:
                        // the spinner is laid out around the badge, never pushing it off
                        // centre.
                        Transform.scale(
                            scale: badge / BrandBadge.size,
                            child: BrandBadge(color: theme.colorScheme.primary),
                        ),
                        Transform.translate(
                            offset: Offset(
                                0,
                                badge / 2 + AppTokens.space32 + 14,
                            ),
                            child: Semantics(
                                label: AppLocalizations.of(context)!.splashLoading,
                                child: SizedBox.square(
                                    dimension: 28,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: theme.colorScheme.primary,
                                    ),
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// [LaunchSplash] on its own, for `main` to show while Firebase and the preferences
/// load — before the router, the providers or the chosen language exist. Khmer, the
/// app's default: the only text is the spinner's screen-reader label.
class LaunchSplashApp extends StatelessWidget {
    const LaunchSplashApp({super.key});

    @override
    Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: const Locale('km'),
        supportedLocales: const [Locale('km'), Locale('en')],
        localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
        ],
        home: const LaunchSplash(),
    );
}
