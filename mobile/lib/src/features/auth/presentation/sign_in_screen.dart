import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import 'auth_failure_message.dart';
import 'telegram_sign_in_sheet.dart';

/// The only unauthenticated screen in the app.
///
/// Three buttons — Google, Facebook, Telegram (FR-AUTH-004) — but still no password
/// field and nothing to forget at 03:00. Google and Facebook are both federated and
/// trade a provider credential for a Firebase session; Telegram is not (ADR 0002 chose
/// Google specifically to avoid an OTP round-trip, then FR-AUTH-004 reintroduced one for
/// this one path). `TelegramSignInSheet` is where that OTP entry lives, not here — this
/// screen only opens it.
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
                body: Center(child: _BrandBadge(color: theme.colorScheme.primary)),
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

        return Scaffold(
            body: SafeArea(
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
                                            _BrandBadge(color: theme.colorScheme.primary),
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
                                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
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
                                        SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                                key: const Key('sign-in-telegram'),
                                                // Not tied to `inFlight`: the Telegram flow has
                                                // its own sheet and its own loading state, and
                                                // closing this button off while an unrelated
                                                // Google/Facebook attempt is in flight would
                                                // strand a donor who changed their mind about
                                                // which provider to use.
                                                onPressed: () => showModalBottomSheet<void>(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    builder: (_) => const TelegramSignInSheet(),
                                                ),
                                                icon: const Icon(Icons.send_outlined),
                                                label: Text(l10n.signInWithTelegram),
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
        );
    }
}

/// The one signature element of the app's only unauthenticated screen — blood is the
/// subject, so the badge is a soft radial glow behind a solid droplet, not a flat icon
/// sitting on blank space. Reused for the cold-start splash so the badge is the first
/// and last thing this screen shows, never swapped for a plain spinner.
class _BrandBadge extends StatelessWidget {
    const _BrandBadge({required this.color});

    final Color color;

    @override
    Widget build(BuildContext context) {
        return Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                ),
                boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 32,
                        spreadRadius: 2,
                    ),
                ],
            ),
            child: const Icon(Icons.bloodtype, size: 52, color: Colors.white),
        );
    }
}
