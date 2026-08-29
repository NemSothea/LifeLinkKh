import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/auth_providers.dart';
import '../domain/telegram_start_session.dart';
import 'auth_failure_message.dart';

/// The Telegram half of sign-in (FR-AUTH-004), opened as a bottom sheet from
/// `SignInScreen` rather than a route — it has no session yet, so it must not trip the
/// router's signed-in/signed-out redirect the way a real screen would.
///
/// Two providers, not one, because the flow has two different things to be wrong about:
/// `telegramStartControllerProvider` owns getting the deep link (no session at stake if
/// this fails — retry is just reopening the sheet); `authControllerProvider` owns the
/// code the donor types back, because success there is a real session and must go
/// through the same state the router watches.
class TelegramSignInSheet extends ConsumerStatefulWidget {
    const TelegramSignInSheet({super.key});

    @override
    ConsumerState<TelegramSignInSheet> createState() => _TelegramSignInSheetState();
}

class _TelegramSignInSheetState extends ConsumerState<TelegramSignInSheet> {
    final _codeController = TextEditingController();

    @override
    void initState() {
        super.initState();
        // Fire-and-forget from initState, not build: this must run exactly once per
        // sheet open, not once per rebuild.
        Future.microtask(() => ref.read(telegramStartControllerProvider.notifier).start());
    }

    @override
    void dispose() {
        _codeController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final start = ref.watch(telegramStartControllerProvider);
        final verify = ref.watch(telegramVerifyControllerProvider);

        // The sheet closes itself once `AuthController.applyTelegramSession` has run,
        // rather than the caller closing it — a dismissed sheet after a failed verify
        // must not be mistaken for a cancel, so this only fires on an actual session.
        // Watching `authControllerProvider` here, not `telegramVerifyControllerProvider`,
        // is deliberate: a wrong code's failure lives on the latter and must not pop
        // this sheet away from the donor who is about to retry.
        ref.listen(authControllerProvider, (previous, next) {
            if (next.valueOrNull != null && previous?.valueOrNull != next.valueOrNull) {
                Navigator.of(context).maybePop();
            }
        });

        final session = start.valueOrNull;
        final verifying = verify.isLoading;

        return Padding(
            padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Text(
                        l10n.telegramSheetTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (start.isLoading)
                        const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                        )
                    else if (start.hasError)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AuthFailureMessage(error: start.error!),
                        )
                    else if (session != null)
                        _CodeEntry(
                            key: const Key('telegram-code-entry'),
                            session: session,
                            codeController: _codeController,
                            verifying: verifying,
                            failure: verify.hasError ? verify.error : null,
                            onSubmit: () => ref
                                .read(telegramVerifyControllerProvider.notifier)
                                .verify(
                                    sessionToken: session.sessionToken,
                                    code: _codeController.text.trim(),
                                ),
                        ),
                ],
            ),
        );
    }
}

class _CodeEntry extends StatelessWidget {
    const _CodeEntry({
        super.key,
        required this.session,
        required this.codeController,
        required this.verifying,
        required this.failure,
        required this.onSubmit,
    });

    final TelegramStartSession session;
    final TextEditingController codeController;
    final bool verifying;
    final Object? failure;
    final VoidCallback onSubmit;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Text(l10n.telegramInstructions, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    key: const Key('telegram-open-app'),
                    onPressed: () =>
                        launchUrl(Uri.parse(session.deepLink), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.telegramOpenApp),
                ),
                const SizedBox(height: 20),
                TextField(
                    key: const Key('telegram-code-field'),
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: InputDecoration(
                        labelText: l10n.telegramCodeLabel,
                        counterText: '',
                    ),
                ),
                if (failure != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: AuthFailureMessage(error: failure!),
                    ),
                const SizedBox(height: 12),
                FilledButton(
                    key: const Key('telegram-submit'),
                    onPressed: verifying ? null : onSubmit,
                    child: verifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(l10n.telegramSubmit),
                ),
            ],
        );
    }
}
