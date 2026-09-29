import 'package:flutter/material.dart';

import '../domain/blood_type.dart';

/// All eight values at once, in a 4×2 grid.
///
/// `FR-DONOR-001` requires every type visible without scrolling and without opening a
/// dropdown, and there is deliberately no "unknown" tile — a profile with an unknown type has
/// no `blood_compatibility` row (ADR 0004) and would never match while looking complete.
///
/// A plain widget with no Riverpod import: it takes a value and a callback, which is what
/// makes it usable on both the setup step and any later screen.
class BloodTypeGrid extends StatelessWidget {
    const BloodTypeGrid({required this.selected, required this.onSelected, super.key});

    final BloodType? selected;
    final ValueChanged<BloodType> onSelected;

    @override
    Widget build(BuildContext context) {
        // Row height from the text, not a fixed number: at least 48dp (the minimum tap
        // target — a 1.6 aspect ratio gave ~45dp on a 360dp phone), and tall enough for
        // the label at whatever text scale the phone is set to.
        final labelHeight = MediaQuery.textScalerOf(context).scale(
            Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
        ) * 1.5;
        return LayoutBuilder(
            builder: (context, constraints) {
                const spacing = 8.0;
                final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
                final rowHeight = [48.0, tileWidth / 1.6, labelHeight + 16]
                    .reduce((a, b) => a > b ? a : b);
                return GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: tileWidth / rowHeight,
            children: [
                for (final type in BloodType.gridOrder)
                    _BloodTypeTile(
                        type: type,
                        isSelected: type == selected,
                        onTap: () => onSelected(type),
                    ),
            ],
                );
            },
        );
    }
}

class _BloodTypeTile extends StatelessWidget {
    const _BloodTypeTile({
        required this.type,
        required this.isSelected,
        required this.onTap,
    });

    final BloodType type;
    final bool isSelected;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;

        return Material(
            color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                    child: Text(
                        // The wire value is also the label: `O-` reads the same in Khmer and
                        // English, so there is nothing to localise here.
                        type.wireValue,
                        key: Key('blood-type-${type.wireValue}'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                    ),
                ),
            ),
        );
    }
}
