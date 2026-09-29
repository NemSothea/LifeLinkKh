import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/brand_backdrop.dart';
import '../../../core/links/link_providers.dart';
import '../../../core/widgets/brand_badge.dart';
import '../../about/application/about_providers.dart';
import '../../about/presentation/about_screen.dart';
import '../../onboarding/presentation/intro_screen.dart';
import '../application/auth_providers.dart';
import 'auth_failure_message.dart';

/// The only unauthenticated screen in the app.
///
/// Two buttons — Google, and Facebook (FR-AUTH-004) — and no password field, nothing to
/// forget at 03:00. Both are federated: each trades a provider credential for a Firebase
/// session, which is the whole of signing in since ADR 0009. Telegram's OTP path went with
/// the backend it needed.
///
/// Four-state rendering (Week 5): idle, in flight, signed in, and failed — where *failed*
/// switches on the sealed `Failure` rather than on a message string, so the compiler
/// checks that every variant has copy and the copy is localised.
class SignInScreen extends ConsumerStatefulWidget {
    const SignInScreen({super.key});

    static const String path = '/sign-in';

    @override
    ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

/// Which button was actually tapped. `authControllerProvider`'s `isLoading` is one flag
/// shared by both federated providers — without this, tapping Google also drew Facebook's
/// button as "Signing in..." (a spinner and copy on a button nobody touched), even though
/// it was correctly disabled underneath.
enum _PendingProvider { google, facebook }

class _SignInScreenState extends ConsumerState<SignInScreen> {
    _PendingProvider? _pending;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final auth = ref.watch(authControllerProvider);
        final theme = Theme.of(context);

        // The very first read of `authControllerProvider` starts `restoreSession()`, which
        // is `isLoading` with no previous value — the same shape the router's own redirect
        // (`app_router.dart`) checks for "still reading the keystore". Rendering the normal
        // button row here would show both providers as "Signing in..." before anything was
        // tapped, for every cold start. A neutral splash instead — gone the instant restore
        // resolves, whichever way.
        if (auth.isLoading && !auth.hasValue) {
            return Scaffold(
                body: Center(child: BrandBadge(color: theme.colorScheme.primary)),
            );
        }

        // `isLoading` rather than a `when`: a re-sign-in after a failure keeps the previous
        // state, and this screen wants the spinner in both cases. Both buttons disable
        // while either is in flight — a second tap must not open a second account chooser
        // — but only the one actually tapped (`_pending`) draws the spinner/"Signing in..."
        // or "Retry" copy. `auth.isLoading`/`auth.hasError` are one flag shared by both
        // providers; without `_pending` the untapped button drew that same state too.
        final inFlight = auth.isLoading;
        final googlePending = _pending == _PendingProvider.google;
        final facebookPending = _pending == _PendingProvider.facebook;

        // The action panel is a full-bleed surface, not an inset card — it should paint
        // through to the physical bottom edge (behind the home indicator), not stop at
        // the safe area and leave a gap of plain background showing underneath.
        final bottomInset = MediaQuery.of(context).padding.bottom;

        return Scaffold(
            body: BrandBackdrop(
                child: SafeArea(
                bottom: false,
                // Not wrapped in a scroll view: `Expanded` below needs the bounded height
                // `SafeArea`/`Scaffold` already provide, and a scroll view would hand it
                // unbounded height instead — the two don't compose. Both zones are small,
                // known content (a badge, three lines, three buttons), so there's nothing
                // realistic to overflow on a phone in portrait.
                child: Column(
                    children: [
                        // Identity zone: the one place this screen is allowed to take a
                        // visual risk, since it's a blank canvas otherwise — everything
                        // below sits on the flat surface Material 3 buttons expect. Expands
                        // to fill whatever space the action panel below doesn't need, so
                        // the panel always sits flush against the bottom edge.
                        Expanded(
                            child: Center(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            BrandBadge(color: theme.colorScheme.primary),
                                            const SizedBox(height: 28),
                                            // The wordmark, not translated — same literal
                                            // "LifeLink KH" the web portal's header uses, so
                                            // the brand mark itself reads identically on both
                                            // clients.
                                            Text(
                                                'LIFELINK KH',
                                                style: theme.textTheme.labelLarge?.copyWith(
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 2,
                                                ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                l10n.signInTitle,
                                                style: theme.textTheme.headlineMedium?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                l10n.signInTagline,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                textAlign: TextAlign.center,
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                        // Action zone: a raised surface groups every sign-in choice into
                        // one block, so the identity zone above stays clean rather than
                        // sharing a flat background with three buttons.
                        Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(24, 28, 24, 32 + bottomInset),
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(28),
                                    ),
                                ),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        if (auth.hasError)
                                            Padding(
                                                padding: const EdgeInsets.only(bottom: 16),
                                                child: AuthFailureMessage(error: auth.error!),
                                            ),
                                        SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                                key: const Key('sign-in-google'),
                                                // Disabled while in flight: a second tap opens
                                                // a second account chooser and the first
                                                // result is discarded.
                                                onPressed: inFlight
                                                    ? null
                                                    : () {
                                                        HapticFeedback.selectionClick();
                                                        setState(
                                                            () => _pending =
                                                                _PendingProvider.google,
                                                        );
                                                        ref
                                                            .read(authControllerProvider.notifier)
                                                            .signIn();
                                                    },
                                                icon: inFlight && googlePending
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                        ),
                                                    )
                                                    : const Icon(Icons.login),
                                                label: Text(
                                                    inFlight && googlePending
                                                        ? l10n.signInSigningIn
                                                        : (auth.hasError && googlePending
                                                            ? l10n.retry
                                                            : l10n.signInWithGoogle),
                                                ),
                                            ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                            children: [
                                                const Expanded(child: Divider()),
                                                Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                    ),
                                                    child: Text(
                                                        l10n.signInMoreOptions,
                                                        style: theme.textTheme.labelSmall
                                                            ?.copyWith(
                                                            color:
                                                                theme.colorScheme.onSurfaceVariant,
                                                        ),
                                                    ),
                                                ),
                                                const Expanded(child: Divider()),
                                            ],
                                        ),
                                        const SizedBox(height: 20),
                                        SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                                key: const Key('sign-in-facebook'),
                                                onPressed: inFlight
                                                    ? null
                                                    : () {
                                                        HapticFeedback.selectionClick();
                                                        setState(
                                                            () => _pending =
                                                                _PendingProvider.facebook,
                                                        );
                                                        ref
                                                            .read(authControllerProvider.notifier)
                                                            .signInWithFacebook();
                                                    },
                                                icon: inFlight && facebookPending
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                        ),
                                                    )
                                                    : const Icon(Icons.facebook),
                                                label: Text(
                                                    inFlight && facebookPending
                                                        ? l10n.signInSigningIn
                                                        : (auth.hasError && facebookPending
                                                            ? l10n.retry
                                                            : l10n.signInWithFacebook),
                                                ),
                                            ),
                                        ),
                                        const SizedBox(height: 12),
                                        const _TrustFooter(),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

/// What someone checks before trusting an app with an account: how it works, what it
/// does with their data, who is behind it, and which version this is. Links rather than
/// content, because this screen does not scroll — each one opens a screen or the
/// browser, and the panel only grows by one row of links and one line of text.
///
/// A `Wrap`, not a `Row`: in Khmer the three labels are wider than a 360 px phone.
class _TrustFooter extends ConsumerWidget {
    const _TrustFooter();

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final version = ref.watch(appVersionProvider).valueOrNull;
        const linkStyle = ButtonStyle(visualDensity: VisualDensity.compact);

        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                        TextButton(
                            key: const Key('sign-in-how-it-works'),
                            style: linkStyle,
                            onPressed: () => context.push(IntroScreen.reviewLocation),
                            child: Text(l10n.signInHowItWorks),
                        ),
                        TextButton(
                            key: const Key('sign-in-privacy'),
                            style: linkStyle,
                            onPressed: () => ref
                                .read(linkOpenerProvider)
                                .open(ref.read(privacyUriProvider)),
                            child: Text(l10n.signInPrivacy),
                        ),
                        TextButton(
                            key: const Key('sign-in-about'),
                            style: linkStyle,
                            onPressed: () => context.push(AboutScreen.path),
                            child: Text(l10n.aboutHelpCta),
                        ),
                    ],
                ),
                if (version != null)
                    Text(
                        'v${version.version} (${version.build})',
                        key: const Key('sign-in-version'),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ),
            ],
        );
    }
}
