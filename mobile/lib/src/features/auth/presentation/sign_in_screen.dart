import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../application/auth_providers.dart';

/// The only unauthenticated screen in the app.
///
/// One button, because there is one method: `ADR 0002` replaced phone OTP with Google
/// Sign-In, so there is no password field, no OTP entry, and nothing to forget at 03:00.
///
/// Four-state rendering (Week 5): idle, in flight, signed in, and failed — where *failed*
/// switches on the sealed [Failure] rather than on a message string, so the compiler
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
                                        child: _FailureMessage(error: auth.error!),
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
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

/// Turns a [Failure] into localised copy. One `switch` over the sealed type, so adding a
/// variant is a compile error here rather than a silent fallthrough to "something went
/// wrong".
class _FailureMessage extends StatelessWidget {
    const _FailureMessage({required this.error});

    /// `Object` because that is what `AsyncError.error` is. A non-[Failure] means a bug
    /// escaped the data layer, and it renders as the generic case rather than crashing.
    final Object error;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        final (IconData icon, String message) = switch (error) {
            NetworkFailure() => (Icons.wifi_off, l10n.signInFailedNetwork),
            UnauthorizedFailure() => (Icons.lock_outline, l10n.signInFailedRejected),
            RateLimitedFailure() => (Icons.timer_outlined, l10n.signInFailedRateLimited),
            ServerFailure() => (Icons.cloud_off, l10n.signInFailedServer),
            // A rejected role and a not-found are both bugs from this screen's point of
            // view: it always asks for DONOR, which is self-service.
            ValidationFailure() || NotFoundFailure() || UnknownFailure() => (
                Icons.error_outline,
                l10n.signInFailedUnknown,
            ),
            _ => (Icons.error_outline, l10n.signInFailedUnknown),
        };

        return Row(
            key: const Key('sign-in-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(icon, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(
                        message,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                    ),
                ),
            ],
        );
    }
}
