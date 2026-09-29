import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// "LifeLink never asks for money. Never pay or accept payment for blood."
///
/// DEC-019. Cambodia's national blood policy makes blood free to the patient, and paid
/// donors and brokers are documented around the blood centre. Both people in a match need
/// to hear it at the moment money could come up: the family as they post, the donor as
/// they answer and once they have the family's number.
class MoneyNotice extends StatelessWidget {
    const MoneyNotice({super.key});

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(Icons.money_off_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                    child: Text(
                        l10n.moneyNotice,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                        ),
                    ),
                ),
            ],
        );
    }
}
