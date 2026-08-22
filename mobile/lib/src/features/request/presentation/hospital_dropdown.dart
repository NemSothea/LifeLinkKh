import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/request_providers.dart';

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
            data: (hospitals) => DropdownButtonFormField<String>(
                key: const Key('request-hospital'),
                initialValue: selectedId,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: l10n.requestHospitalLabel,
                    border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.requestHospitalHint),
                items: [
                    for (final hospital in hospitals)
                        DropdownMenuItem(
                            value: hospital.id,
                            child: Text(
                                switch (hospital.districtLabel(languageCode)) {
                                    final String district => '${hospital.name} · $district',
                                    null => hospital.name,
                                },
                                overflow: TextOverflow.ellipsis,
                            ),
                        ),
                ],
                onChanged: (id) {
                    if (id != null) onSelected(id);
                },
            ),
        );
    }
}
