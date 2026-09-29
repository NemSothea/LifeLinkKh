import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/inline_error.dart';
import '../application/report_providers.dart';
import '../domain/report_reason.dart';

/// "Report this request" — DEC-019. For a donor who was asked for money, suspects the
/// request is fake, or was harassed. Goes to the admin, nobody else. Returns true when sent.
Future<bool?> showReportRequestSheet(BuildContext context, {required String requestId}) =>
    showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => _ReportRequestSheet(requestId: requestId),
    );

class _ReportRequestSheet extends ConsumerStatefulWidget {
    const _ReportRequestSheet({required this.requestId});

    final String requestId;

    @override
    ConsumerState<_ReportRequestSheet> createState() => _ReportRequestSheetState();
}

class _ReportRequestSheetState extends ConsumerState<_ReportRequestSheet> {
    ReportReason? _reason;
    final TextEditingController _note = TextEditingController();
    bool _sending = false;
    Failure? _failure;

    @override
    void dispose() {
        _note.dispose();
        super.dispose();
    }

    Future<void> _send() async {
        final reason = _reason;
        if (reason == null) return;
        setState(() {
            _sending = true;
            _failure = null;
        });
        final result = await ref.read(reportRepositoryProvider).report(
            requestId: widget.requestId,
            reason: reason,
            note: _note.text,
        );
        if (!mounted) return;
        switch (result) {
            case Success():
                Navigator.of(context).pop(true);
            case Failed(:final failure):
                HapticFeedback.heavyImpact();
                setState(() {
                    _sending = false;
                    _failure = failure;
                });
        }
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final reasons = [
            (ReportReason.money, l10n.reportReasonMoney),
            (ReportReason.fake, l10n.reportReasonFake),
            (ReportReason.harassment, l10n.reportReasonHarassment),
            (ReportReason.other, l10n.reportReasonOther),
        ];

        return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                AppTokens.space24,
                0,
                AppTokens.space24,
                AppTokens.space24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
                key: const Key('report-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Text(
                        l10n.reportTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                        l10n.reportBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    RadioGroup<ReportReason>(
                        groupValue: _reason,
                        onChanged: (value) => setState(() => _reason = value),
                        child: Column(
                            children: [
                                for (final (reason, label) in reasons)
                                    RadioListTile<ReportReason>(
                                        key: Key('report-reason-${reason.wireValue}'),
                                        contentPadding: EdgeInsets.zero,
                                        value: reason,
                                        title: Text(label),
                                    ),
                            ],
                        ),
                    ),
                    const SizedBox(height: AppTokens.space8),
                    TextField(
                        key: const Key('report-note'),
                        controller: _note,
                        maxLength: 500,
                        maxLines: 3,
                        minLines: 2,
                        decoration: InputDecoration(labelText: l10n.reportNoteLabel),
                    ),
                    if (_failure != null) ...[
                        const SizedBox(height: AppTokens.space8),
                        InlineError(
                            key: const Key('report-failed'),
                            // Refused by the rules is almost always "you already reported this".
                            message: _failure is ForbiddenFailure
                                ? l10n.reportAlreadySent
                                : l10n.reportFailed,
                            error: _failure,
                        ),
                    ],
                    const SizedBox(height: AppTokens.space16),
                    FilledButton(
                        key: const Key('report-send'),
                        onPressed: _reason == null || _sending ? null : _send,
                        child: Text(_sending ? l10n.reportSending : l10n.reportSendCta),
                    ),
                ],
            ),
        );
    }
}
