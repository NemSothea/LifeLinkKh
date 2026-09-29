import 'package:flutter/material.dart';

/// One card of a static guide: an icon, a heading, and a list of short ticked lines.
/// Shared by the donor's "what to expect" guide and the family's "how getting blood works"
/// guide, so both read as one voice.
class GuideSection extends StatelessWidget {
    const GuideSection({
        required this.icon,
        required this.title,
        required this.items,
        super.key,
    });

    final IconData icon;
    final String title;
    final List<String> items;

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);

        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            children: [
                                Icon(icon, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(title, style: theme.textTheme.titleMedium),
                                ),
                            ],
                        ),
                        const SizedBox(height: 8),
                        for (final item in items)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        const Padding(
                                            padding: EdgeInsets.only(top: 2, right: 10),
                                            child: Icon(Icons.check, size: 18),
                                        ),
                                        Expanded(
                                            child: Text(item, style: theme.textTheme.bodyMedium),
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
