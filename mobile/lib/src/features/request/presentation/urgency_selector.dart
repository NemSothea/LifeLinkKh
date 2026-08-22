import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/urgency.dart';

/// The 3-segment urgency control from the wireframe — a segmented control rather
/// than a dropdown, because urgency changes nothing about the form and everything
/// about how the request reads to a donor, so it should always be visible at once.
class UrgencySelector extends StatelessWidget {
    const UrgencySelector({required this.selected, required this.onSelected, super.key});

    final Urgency selected;
    final ValueChanged<Urgency> onSelected;

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;

        String labelFor(Urgency urgency) => switch (urgency) {
            Urgency.critical => l10n.requestUrgencyCritical,
            Urgency.urgent => l10n.requestUrgencyUrgent,
            Urgency.routine => l10n.requestUrgencyRoutine,
        };

        return SegmentedButton<Urgency>(
            key: const Key('request-urgency'),
            segments: [
                for (final urgency in Urgency.segmentOrder)
                    ButtonSegment(value: urgency, label: Text(labelFor(urgency))),
            ],
            selected: {selected},
            onSelectionChanged: (values) => onSelected(values.first),
        );
    }
}
