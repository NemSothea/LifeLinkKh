import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/avatar_spec.dart';
import 'profile_avatar.dart';

/// Opens the picker and resolves to the chosen avatar, or null when dismissed.
Future<AvatarSpec?> showAvatarPicker(BuildContext context, AvatarSpec current) =>
    showModalBottomSheet<AvatarSpec>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => AvatarPickerSheet(current: current),
    );

/// A male/female switch over a grid of generated faces, and a button that deals a new
/// grid. Tapping a face picks it and closes the sheet — there is no separate "save",
/// because a choice this small should not need confirming.
class AvatarPickerSheet extends StatefulWidget {
    const AvatarPickerSheet({super.key, required this.current});

    final AvatarSpec current;

    /// How many faces one deal shows: two rows of four fit a phone without scrolling.
    static const int optionCount = 8;

    @override
    State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
    late AvatarGender _gender = widget.current.gender;

    /// The first cell of a deal. Starts at the current face so the user sees what they
    /// have, highlighted, before choosing to change it.
    late int _baseSeed = widget.current.seed;

    List<AvatarSpec> get _options => [
        for (var i = 0; i < AvatarPickerSheet.optionCount; i++)
            AvatarSpec(
                gender: _gender,
                seed: i == 0 ? _baseSeed : stableHash('$_baseSeed:$i'),
            ),
    ];

    void _shuffle() => setState(() => _baseSeed = stableHash('$_baseSeed:shuffle'));

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final options = _options;

        return SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.space16,
                    0,
                    AppTokens.space16,
                    AppTokens.space16,
                ),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Text(l10n.avatarPickerTitle, style: theme.textTheme.titleLarge),
                        const SizedBox(height: AppTokens.space16),
                        SegmentedButton<AvatarGender>(
                            key: const Key('avatar-gender'),
                            showSelectedIcon: false,
                            segments: [
                                ButtonSegment(
                                    value: AvatarGender.male,
                                    label: Text(l10n.avatarMale),
                                    icon: const Icon(Icons.male),
                                ),
                                ButtonSegment(
                                    value: AvatarGender.female,
                                    label: Text(l10n.avatarFemale),
                                    icon: const Icon(Icons.female),
                                ),
                            ],
                            selected: {_gender},
                            onSelectionChanged: (selection) =>
                                setState(() => _gender = selection.first),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: AppTokens.space12,
                            crossAxisSpacing: AppTokens.space12,
                            children: [
                                for (final (index, option) in options.indexed)
                                    _Option(
                                        key: Key('avatar-option-$index'),
                                        spec: option,
                                        selected: option == widget.current,
                                        label: l10n.avatarOptionLabel(index + 1),
                                        onTap: () => Navigator.of(context).pop(option),
                                    ),
                            ],
                        ),
                        const SizedBox(height: AppTokens.space16),
                        OutlinedButton.icon(
                            key: const Key('avatar-shuffle'),
                            onPressed: _shuffle,
                            icon: const Icon(Icons.shuffle),
                            label: Text(l10n.avatarShuffle),
                        ),
                    ],
                ),
            ),
        );
    }
}

class _Option extends StatelessWidget {
    const _Option({
        super.key,
        required this.spec,
        required this.selected,
        required this.label,
        required this.onTap,
    });

    final AvatarSpec spec;
    final bool selected;
    final String label;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final scheme = Theme.of(context).colorScheme;
        return Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: selected ? scheme.primary : Colors.transparent,
                            width: 3,
                        ),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: LayoutBuilder(
                            builder: (context, constraints) => ProfileAvatar(
                                spec: spec,
                                radius: constraints.biggest.shortestSide / 2,
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}
