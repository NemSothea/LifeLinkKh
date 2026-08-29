import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/searchable_picker.dart';
import '../application/request_providers.dart';
import '../domain/hospital.dart';

/// The hospital picker, fed by `GET /hospitals`. Same shape as `DistrictDropdown`
/// and for the same reason: `hospitalId` is a foreign key, so the list is fetched,
/// never bundled.
class HospitalDropdown extends ConsumerWidget {
    const HospitalDropdown({required this.selectedId, required this.onSelected, super.key});

    final String? selectedId;
    final ValueChanged<String> onSelected;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final languageCode = Localizations.localeOf(context).languageCode;

        return ref.watch(hospitalsProvider).when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(key: Key('hospitals-loading')),
            ),
            error: (_, _) => Row(
                key: const Key('hospitals-failed'),
                children: [
                    Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(l10n.requestHospitalsFailed)),
                    TextButton(
                        onPressed: () => ref.invalidate(hospitalsProvider),
                        child: Text(l10n.retry),
                    ),
                ],
            ),
            data: (hospitals) => SearchablePicker<Hospital>(
                key: const Key('request-hospital'),
                items: hospitals,
                selected: _selectedOrNull(hospitals, selectedId),
                labelBuilder: (h) => _label(h, languageCode),
                // Typing a district also surfaces hospitals in it, even though the
                // closed field and the sheet's rows only show `_label`.
                searchableTextBuilder: (h) =>
                    '${h.name} ${h.districtLabel(languageCode) ?? ''}',
                itemKey: (h) => Key('hospital-option-${h.id}'),
                onSelected: (h) => onSelected(h.id),
                fieldLabel: l10n.requestHospitalLabel,
                hintText: l10n.requestHospitalHint,
                searchHint: l10n.pickerSearchHint,
                noResultsText: l10n.pickerNoResults,
            ),
        );
    }

    String _label(Hospital hospital, String languageCode) =>
        switch (hospital.districtLabel(languageCode)) {
            final String district => '${hospital.name} · $district',
            null => hospital.name,
        };

    Hospital? _selectedOrNull(List<Hospital> hospitals, String? id) {
        if (id == null) return null;
        for (final hospital in hospitals) {
            if (hospital.id == id) return hospital;
        }
        return null;
    }
}
