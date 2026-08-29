import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/searchable_picker.dart';
import '../application/donor_providers.dart';
import '../domain/district.dart';

/// The district picker, fed by `GET /districts`.
///
/// The list is not bundled in the app: `districtCode` is a foreign key, so a stale local copy
/// produces a 422 that tells a donor their own district is invalid.
///
/// Order comes from the server and is not re-sorted here — Khmer collation on the device would
/// need its own implementation and could disagree with the web portal.
class DistrictDropdown extends ConsumerWidget {
    const DistrictDropdown({
        required this.selectedCode,
        required this.onSelected,
        super.key,
    });

    final String? selectedCode;
    final ValueChanged<String> onSelected;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final languageCode = Localizations.localeOf(context).languageCode;

        return ref.watch(districtsProvider).when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(key: Key('districts-loading')),
            ),
            error: (_, _) => Row(
                key: const Key('districts-failed'),
                children: [
                    Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(l10n.donorDistrictsFailed)),
                    TextButton(
                        onPressed: () => ref.invalidate(districtsProvider),
                        child: Text(l10n.retry),
                    ),
                ],
            ),
            data: (districts) => SearchablePicker<District>(
                key: const Key('donor-district'),
                items: districts,
                selected: _selectedOrNull(districts, selectedCode),
                labelBuilder: (d) => d.label(languageCode),
                searchableTextBuilder: (d) => d.label(languageCode),
                itemKey: (d) => Key('district-option-${d.code}'),
                onSelected: (d) => onSelected(d.code),
                fieldLabel: l10n.donorDistrictLabel,
                hintText: l10n.donorDistrictHint,
                searchHint: l10n.pickerSearchHint,
                noResultsText: l10n.pickerNoResults,
            ),
        );
    }

    District? _selectedOrNull(List<District> districts, String? code) {
        if (code == null) return null;
        for (final district in districts) {
            if (district.code == code) return district;
        }
        return null;
    }
}
