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
class SignInScreen extends ConsumerWidget {
    const SignInScreen({super.key});

    static const String path = '/sign-in';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final auth = ref.watch(authControllerProvider);
        final theme = Theme.of(context);

        // `isLoading` rather than a `when`: a re-sign-in after a failure keeps the previous
        // state, and this screen wants the spinner in both cases.
        final inFlight = auth.isLoading;

        return Scaffold(
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(
                                    Icons.bloodtype_outlined,
                                    size: 64,
                                    color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                    l10n.signInTitle,
                                    style: theme.textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    l10n.signInTagline,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                if (auth.hasError)
                                    Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: AuthFailureMessage(error: auth.error!),
                                    ),
                                FilledButton.icon(
                                    key: const Key('sign-in-google'),
                                    // Disabled while in flight: a second tap opens a second
                                    // account chooser and the first result is discarded.
                                    onPressed: inFlight
                                        ? null
                                        : () => ref.read(authControllerProvider.notifier).signIn(),
                                    icon: inFlight
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                        : const Icon(Icons.login),
                                    label: Text(
                                        inFlight
                                            ? l10n.signInSigningIn
                                            : (auth.hasError
                                                ? l10n.retry
                                                : l10n.signInWithGoogle),
                                    ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    key: const Key('sign-in-facebook'),
                                    onPressed: inFlight
                                        ? null
                                        : () => ref
                                            .read(authControllerProvider.notifier)
                                            .signInWithFacebook(),
                                    icon: inFlight
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                        : const Icon(Icons.facebook),
                                    label: Text(
                                        inFlight ? l10n.signInSigningIn : l10n.signInWithFacebook,
                                    ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                    key: const Key('sign-in-telegram'),
                                    // Not tied to `inFlight`: the Telegram flow has its own
                                    // sheet and its own loading state, and closing this button
                                    // off while an unrelated Google/Facebook attempt is in
                                    // flight would strand a donor who changed their mind about
                                    // which provider to use.
                                    onPressed: () => showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => const TelegramSignInSheet(),
                                    ),
                                    icon: const Icon(Icons.send_outlined),
                                    label: Text(l10n.signInWithTelegram),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
