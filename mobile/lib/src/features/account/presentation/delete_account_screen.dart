import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../auth/application/auth_providers.dart';
import '../application/account_deletion_service.dart';
import '../application/account_providers.dart';
import '../domain/account_deletion.dart';
import '../domain/account_repository.dart';

/// The confirmation step of DEC-016's in-app account deletion — the page Google Play's
/// policy asks for.
///
/// A screen rather than a dialog: what deletion does takes five sentences, and each one is
/// a thing a donor might not expect (their open request closes; an acceptance they gave is
/// withdrawn). The Me tab's row only brings you here; nothing is deleted until
/// "Delete my account" is pressed on this screen, and then the provider's own sign-in
/// dialog is a third, deliberate step.
class DeleteAccountScreen extends ConsumerStatefulWidget {
    const DeleteAccountScreen({super.key});

    static const String path = '/account/delete';

    @override
    ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
    bool _isDeleting = false;
    Failure? _failure;

    Future<void> _delete() async {
        // Captured before the await: on success the router replaces this screen with
        // sign-in, and the message has to land there, not on a disposed context.
        final messenger = ScaffoldMessenger.of(context);
        final l10n = AppLocalizations.of(context)!;

        setState(() {
            _isDeleting = true;
            _failure = null;
        });
        final result = await ref.read(accountDeletionServiceProvider).deleteAccount();

        switch (result) {
            case Success<AccountDeletion?>(value: null):
                // Re-authentication dismissed. Back to where the donor was, as if they had
                // pressed "Keep my account" — nothing was deleted, so nothing is said.
                if (mounted) Navigator.of(context).pop();
            case Success<AccountDeletion?>():
                ref.read(authControllerProvider.notifier).accountDeleted();
                messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
            case Failed<AccountDeletion?>(failure: final failure):
                if (!mounted) return;
                setState(() {
                    _isDeleting = false;
                    _failure = failure;
                });
        }
    }

    static String _messageFor(AppLocalizations l10n, Failure failure) => switch (failure) {
        NetworkFailure() => l10n.accountDeleteFailedNetwork,
        ForbiddenFailure(code: AccountDeletionService.differentAccount) =>
            l10n.accountDeleteFailedDifferentAccount,
        ForbiddenFailure(code: AccountRepository.recentSignInRequired) =>
            l10n.accountDeleteFailedRecentSignIn,
        ForbiddenFailure(code: AccountRepository.adminAccount) => l10n.accountDeleteFailedAdmin,
        _ => l10n.accountDeleteFailed,
    };

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final failure = _failure;

        return PopScope(
            // Leaving mid-call would not stop the deletion, only hide its outcome.
            canPop: !_isDeleting,
            child: Scaffold(
                appBar: AppBar(title: Text(l10n.accountDeleteCta)),
                body: SafeArea(
                    child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                            Icon(
                                Icons.warning_amber_rounded,
                                size: 40,
                                color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.accountDeleteTitle, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            Text(l10n.accountDeleteIntro, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 12),
                            _Consequence(Icons.person_off_outlined, l10n.accountDeleteWhatDeleted),
                            _Consequence(Icons.cancel_outlined, l10n.accountDeleteWhatClosed),
                            _Consequence(Icons.undo, l10n.accountDeleteWhatWithdrawn),
                            _Consequence(Icons.bar_chart, l10n.accountDeleteWhatKept),
                            const SizedBox(height: 16),
                            Text(
                                l10n.accountDeleteIrreversible,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                ),
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.accountDeleteReauthHint, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 32),
                            if (failure != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                        _messageFor(l10n, failure),
                                        key: const Key('delete-account-error'),
                                        style: TextStyle(color: theme.colorScheme.error),
                                    ),
                                ),
                            FilledButton(
                                key: const Key('delete-account-confirm'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                ),
                                onPressed: _isDeleting ? null : _delete,
                                child: Text(
                                    _isDeleting ? l10n.accountDeleting : l10n.accountDeleteConfirmCta,
                                ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                                key: const Key('delete-account-keep'),
                                onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                                child: Text(l10n.accountDeleteKeepCta),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

class _Consequence extends StatelessWidget {
    const _Consequence(this.icon, this.text);

    final IconData icon;
    final String text;

    @override
    Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
            ],
        ),
    );
}
