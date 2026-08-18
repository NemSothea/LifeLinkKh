import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/donor_providers.dart';

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
            data: (districts) => DropdownButtonFormField<String>(
                key: const Key('donor-district'),
                initialValue: selectedCode,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: l10n.donorDistrictLabel,
                    border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.donorDistrictHint),
                items: [
                    for (final district in districts)
                        DropdownMenuItem(
                            value: district.code,
                            child: Text(district.label(languageCode)),
                        ),
                ],
                onChanged: (code) {
                    if (code != null) onSelected(code);
                },
            ),
        );
    }
}
