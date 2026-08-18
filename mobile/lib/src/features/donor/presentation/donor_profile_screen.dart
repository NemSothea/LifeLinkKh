import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/donor_providers.dart';
import '../domain/donor_profile.dart';
import 'donor_setup_screen.dart';
import 'eligibility_card.dart';

/// The donor's own profile: what is on record, whether they may donate today, and the
/// availability toggle.
///
/// Four states (Week 5) — loading, no profile yet, loaded, and failed with a retry. "No profile
/// yet" is a real state and not an error: it is where every donor starts and where every
/// REQUESTER stays.
class DonorProfileScreen extends ConsumerWidget {
    const DonorProfileScreen({super.key});

    static const String path = '/donor/profile';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final profile = ref.watch(donorProfileControllerProvider);

        return Scaffold(
            appBar: AppBar(
                title: Text(l10n.donorProfileTitle),
                actions: [
                    if (profile.valueOrNull != null)
                        IconButton(
                            key: const Key('donor-edit'),
                            tooltip: l10n.donorEdit,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => context.push(DonorSetupScreen.path),
                        ),
                ],
            ),
            body: SafeArea(
                child: switch (profile) {
                    // `hasValue` first: a failed save keeps the previous profile underneath, and a
                    // registered donor must not be shown a "register now" screen because one
                    // write failed.
                    AsyncValue(hasValue: true, value: final DonorProfile loaded) =>
                        _loaded(context, ref, loaded),
                    AsyncValue(hasValue: true) => _noProfileYet(context),
                    AsyncError() => _failed(context, ref),
                    _ => const Center(
                        child: CircularProgressIndicator(key: Key('donor-profile-loading')),
                    ),
                },
            ),
        );
    }

    Widget _loaded(BuildContext context, WidgetRef ref, DonorProfile profile) {
        final l10n = AppLocalizations.of(context)!;
        final languageCode = Localizations.localeOf(context).languageCode;
        final lastDonation = profile.lastDonationDate;

        return ListView(
            padding: const EdgeInsets.all(24),
            children: [
                EligibilityCard(eligibility: profile.eligibility),
                const SizedBox(height: 24),
                _Field(label: l10n.donorFullNameLabel, value: profile.fullName),
                _Field(
                    label: l10n.donorBloodTypeLabel,
                    value: profile.bloodType.wireValue,
                    valueKey: const Key('donor-blood-type-value'),
                ),
                _Field(
                    label: l10n.donorDistrictLabel,
                    // Never a coordinate. District is the only location any screen shows,
                    // including this one (ADR 0003).
                    value: profile.districtLabel(languageCode),
                    valueKey: const Key('donor-district-value'),
                ),
                _Field(
                    label: l10n.donorLastDonationLabel,
                    value: lastDonation == null
                        ? l10n.donorNoDonationYet
                        : DateFormat.yMMMd(languageCode).format(lastDonation),
                ),
                const Divider(height: 32),
                SwitchListTile(
                    key: const Key('donor-availability'),
                    title: Text(l10n.donorAvailableLabel),
                    subtitle: Text(l10n.donorAvailableHint),
                    value: profile.isAvailable,
                    // A full PUT under the hood: the endpoint replaces the row, so the toggle
                    // sends the whole profile with one field changed.
                    onChanged: (value) => ref
                        .read(donorProfileControllerProvider.notifier)
                        .setAvailability(value),
                ),
                if (ref.watch(donorProfileControllerProvider).hasError)
                    Text(
                        l10n.donorSaveFailed,
                        key: const Key('donor-profile-save-failed'),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
            ],
        );
    }

    Widget _noProfileYet(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;

        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(Icons.person_add_alt, size: 56),
                        const SizedBox(height: 16),
                        Text(l10n.donorProfileCta, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                            key: const Key('donor-start-setup'),
                            onPressed: () => context.push(DonorSetupScreen.path),
                            child: Text(l10n.donorSetupTitle),
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _failed(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;

        return Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                            l10n.donorProfileFailed,
                            key: const Key('donor-profile-failed'),
                            textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // The retry the health screen could not justify: this one refetches
                        // something the donor cares about.
                        FilledButton(
                            key: const Key('donor-profile-retry'),
                            onPressed: () => ref.invalidate(donorProfileControllerProvider),
                            child: Text(l10n.retry),
                        ),
                    ],
                ),
            ),
        );
    }
}

class _Field extends StatelessWidget {
    const _Field({required this.label, required this.value, this.valueKey});

    final String label;
    final String value;
    final Key? valueKey;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                    Text(
                        value,
                        key: valueKey,
                        style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
            ),
        );
    }
}
