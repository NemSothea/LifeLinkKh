import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/settings/onboarding_controller.dart';
import '../../auth/presentation/sign_in_screen.dart';

/// The first thing a new install shows, and the only screen in the app that exists to
/// explain rather than to do.
///
/// A donor opens this app perhaps three times a year. Before this screen the first thing
/// they saw was a sign-in button for a product nobody had told them about — the app
/// asked for a Google account before it said what it wanted one for. Three slides is the
/// smallest thing that answers "why should I?" ahead of "sign in".
///
/// **Skippable from the first slide, and shown once.** Anyone who already knows what the
/// app is should reach sign-in in one tap, and a donor who answers an emergency alert at
/// 03:00 must never meet a carousel on the way. `OnboardingController.complete()` runs on
/// both paths — skipping is a legitimate way to finish, not an escape from it.
class IntroScreen extends ConsumerStatefulWidget {
    const IntroScreen({super.key});

    static const String path = '/intro';

    @override
    ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
    final PageController _pages = PageController();
    int _index = 0;

    @override
    void dispose() {
        _pages.dispose();
        super.dispose();
    }

    /// Marks the intro done, then leaves. `go` rather than `push`: the intro must not sit
    /// under sign-in on the back stack, or the system back button re-enters a screen the
    /// donor has already dismissed.
    Future<void> _finish() async {
        await ref.read(onboardingControllerProvider.notifier).complete();
        if (mounted) context.go(SignInScreen.path);
    }

    void _next(int slideCount) {
        if (_index >= slideCount - 1) {
            _finish();
            return;
        }
        _pages.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
        );
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        // Built here rather than as a top-level const: every string is localised, so the
        // list cannot be built until there is a BuildContext to resolve them against.
        final slides = <_Slide>[
            _Slide(
                icon: Icons.volunteer_activism_outlined,
                title: l10n.introLivesTitle,
                body: l10n.introLivesBody,
            ),
            _Slide(
                icon: Icons.notifications_active_outlined,
                title: l10n.introAlertTitle,
                body: l10n.introAlertBody,
            ),
            _Slide(
                icon: Icons.event_available_outlined,
                title: l10n.introEligibleTitle,
                body: l10n.introEligibleBody,
            ),
        ];
        final isLast = _index == slides.length - 1;

        return Scaffold(
            body: SafeArea(
                child: Column(
                    children: [
                        Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                key: const Key('intro-skip'),
                                onPressed: _finish,
                                child: Text(l10n.introSkip),
                            ),
                        ),
                        Expanded(
                            child: PageView.builder(
                                controller: _pages,
                                itemCount: slides.length,
                                onPageChanged: (i) => setState(() => _index = i),
                                itemBuilder: (context, i) => slides[i],
                            ),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                for (var i = 0; i < slides.length; i++)
                                    AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        height: 8,
                                        width: i == _index ? 24 : 8,
                                        decoration: BoxDecoration(
                                            color: i == _index
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.primary.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(4),
                                        ),
                                    ),
                            ],
                        ),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                            child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    key: const Key('intro-next'),
                                    onPressed: () => _next(slides.length),
                                    child: Text(isLast ? l10n.introStart : l10n.introNext),
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// One slide: an icon, a claim, and the sentence that backs it up.
class _Slide extends StatelessWidget {
    const _Slide({required this.icon, required this.title, required this.body});

    final IconData icon;
    final String title;
    final String body;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 56, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 32),
                    Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        body,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ),
                ],
            ),
        );
    }
}
