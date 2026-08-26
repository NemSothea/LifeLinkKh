import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../../../core/location/location_providers.dart';
import '../application/donor_providers.dart';
import '../application/donor_setup_controller.dart';
import '../domain/donor_profile.dart';
import 'blood_type_grid.dart';
import 'district_dropdown.dart';
import 'eligibility_card.dart';

/// The three-step donor setup from `FR-DONOR-001`: name and blood type → location → last
/// donation, with a progress bar, then a one-shot eligibility result.
///
/// Also the edit screen. Editing an existing profile is the same three steps with the fields
/// filled in — a second screen would be the same form twice, and they would drift.
///
/// `ConsumerStatefulWidget` for two specific reasons, neither of them UI state: the name field
/// needs a `TextEditingController` with a lifecycle, and the flow has to be seeded from an
/// existing profile exactly once. Everything the user is filling in lives in
/// `donorSetupProvider`.
class DonorSetupScreen extends ConsumerStatefulWidget {
    const DonorSetupScreen({super.key});

    static const String path = '/donor/setup';

    @override
    ConsumerState<DonorSetupScreen> createState() => _DonorSetupScreenState();
}

class _DonorSetupScreenState extends ConsumerState<DonorSetupScreen> {
    final TextEditingController _name = TextEditingController();

    /// The saved profile, once there is one. Held here rather than in the provider because it
    /// is the screen's own "what do I render now" flag; the profile itself lives in
    /// `donorProfileControllerProvider`.
    DonorProfile? _saved;
    bool _isSaving = false;
    bool _saveFailed = false;

    bool _isLocating = false;
    /// `null` = not tried this visit. Set on every attempt so the message reflects the most
    /// recent tap, not a stale one from before the donor navigated away and back.
    bool? _locationSucceeded;

    @override
    void initState() {
        super.initState();
        // Edit mode: an existing profile becomes the starting draft. Read, not watch — seeding
        // twice would throw away what the user has typed.
        final existing = ref.read(donorProfileControllerProvider).valueOrNull;
        if (existing != null) {
            final draft = ref.read(donorServiceProvider).draftFrom(existing);
            _name.text = draft.fullName;
            // After the first frame: `seed` notifies listeners, and a provider must not be
            // mutated while the widget tree is still building.
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => ref.read(donorSetupProvider.notifier).seed(draft),
            );
        }
    }

    @override
    void dispose() {
        _name.dispose();
        super.dispose();
    }

    Future<void> _save() async {
        final draft = ref.read(donorSetupProvider).draft;
        setState(() {
            _isSaving = true;
            _saveFailed = false;
        });
        final result = await ref.read(donorProfileControllerProvider.notifier).save(draft);
        if (!mounted) return;
        setState(() {
            _isSaving = false;
            switch (result) {
                case Success(value: final profile):
                    _saved = profile;
                case Failed():
                    _saveFailed = true;
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final setup = ref.watch(donorSetupProvider);
        final saved = _saved;

        return Scaffold(
            appBar: AppBar(
                title: Text(
                    saved != null
                        ? l10n.donorSavedTitle
                        : (setup.draft.isComplete && _name.text.isNotEmpty
                            ? l10n.donorEditTitle
                            : l10n.donorSetupTitle),
                ),
            ),
            body: SafeArea(
                child: saved != null ? _result(context, saved) : _steps(context, setup),
            ),
        );
    }

    Widget _result(BuildContext context, DonorProfile profile) {
        final l10n = AppLocalizations.of(context)!;

        return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(
                        Icons.verified_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                        l10n.donorSavedTitle,
                        key: const Key('donor-saved'),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    EligibilityCard(eligibility: profile.eligibility),
                    const SizedBox(height: 24),
                    FilledButton(
                        key: const Key('donor-done'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: Text(l10n.donorDone),
                    ),
                ],
            ),
        );
    }

    Widget _steps(BuildContext context, DonorSetupState setup) {
        final l10n = AppLocalizations.of(context)!;

        return Column(
            children: [
                LinearProgressIndicator(
                    key: const Key('donor-setup-progress'),
                    value: (setup.step + 1) / DonorSetupState.stepCount,
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                            l10n.donorStepOf(setup.step + 1, DonorSetupState.stepCount),
                            style: Theme.of(context).textTheme.labelMedium,
                        ),
                    ),
                ),
                Expanded(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: switch (setup.step) {
                            0 => _identityStep(context, setup),
                            1 => _locationStep(context, setup),
                            _ => _donationStep(context, setup),
                        },
                    ),
                ),
                if (_saveFailed)
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                            l10n.donorSaveFailed,
                            key: const Key('donor-save-failed'),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                    ),
                Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                        children: [
                            if (!setup.isFirstStep)
                                TextButton(
                                    key: const Key('donor-back'),
                                    onPressed: ref.read(donorSetupProvider.notifier).back,
                                    child: Text(l10n.donorBack),
                                ),
                            const Spacer(),
                            FilledButton(
                                key: const Key('donor-next'),
                                // Disabled rather than validated on tap: the donor can see what
                                // is missing on the step they are standing on.
                                onPressed: !setup.canAdvance || _isSaving
                                    ? null
                                    : (setup.isLastStep
                                        ? _save
                                        : ref.read(donorSetupProvider.notifier).next),
                                child: Text(
                                    setup.isLastStep
                                        ? (_isSaving ? l10n.donorSaving : l10n.donorSave)
                                        : l10n.donorContinue,
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        );
    }

    Widget _identityStep(BuildContext context, DonorSetupState setup) {
        final l10n = AppLocalizations.of(context)!;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    l10n.donorIdentityStepTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                    key: const Key('donor-full-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                        labelText: l10n.donorFullNameLabel,
                        border: const OutlineInputBorder(),
                    ),
                    onChanged: ref.read(donorSetupProvider.notifier).setFullName,
                ),
                const SizedBox(height: 24),
                Text(l10n.donorBloodTypeLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                BloodTypeGrid(
                    selected: setup.draft.bloodType,
                    onSelected: ref.read(donorSetupProvider.notifier).setBloodType,
                ),
                const SizedBox(height: 12),
                Text(
                    l10n.donorBloodTypeUnknownHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
        );
    }

    Widget _locationStep(BuildContext context, DonorSetupState setup) {
        final l10n = AppLocalizations.of(context)!;
        final hasCoordinates = setup.draft.latitude != null && setup.draft.longitude != null;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    l10n.donorLocationStepTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DistrictDropdown(
                    selectedCode: setup.draft.districtCode,
                    onSelected: ref.read(donorSetupProvider.notifier).setDistrict,
                ),
                const SizedBox(height: 16),
                // The user-facing half of ADR 0003. The promise is only worth making because
                // no donor endpoint returns coordinates.
                Row(
                    children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                            child: Text(
                                l10n.donorLocationPrivacy,
                                style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ),
                    ],
                ),
                const SizedBox(height: 16),
                // Optional (ADR 0003): a district-only profile is complete and matchable — it
                // simply sorts NULLS LAST. Declining here must never block setup.
                OutlinedButton.icon(
                    key: const Key('donor-use-current-location'),
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    icon: hasCoordinates && !_isLocating
                        ? const Icon(Icons.check, size: 18)
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                        _isLocating
                            ? l10n.donorAcquiringLocation
                            : (hasCoordinates
                                ? l10n.donorLocationAdded
                                : l10n.donorUseCurrentLocation),
                    ),
                ),
                if (_locationSucceeded == false)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                            l10n.donorLocationUnavailable,
                            key: const Key('donor-location-unavailable'),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                    ),
            ],
        );
    }

    Future<void> _useCurrentLocation() async {
        setState(() {
            _isLocating = true;
            _locationSucceeded = null;
        });
        final fix = await ref.read(locationServiceProvider).currentFix();
        if (!mounted) return;
        if (fix != null) {
            ref
                .read(donorSetupProvider.notifier)
                .setCoordinates(fix.latitude, fix.longitude);
        }
        setState(() {
            _isLocating = false;
            _locationSucceeded = fix != null;
        });
    }

    Widget _donationStep(BuildContext context, DonorSetupState setup) {
        final l10n = AppLocalizations.of(context)!;
        final date = setup.draft.lastDonationDate;

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                    l10n.donorDonationStepTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(l10n.donorLastDonationLabel),
                const SizedBox(height: 8),
                Text(
                    date == null
                        ? l10n.donorNoDonationYet
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).languageCode,
                        ).format(date),
                    key: const Key('donor-last-donation-value'),
                    style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                    children: [
                        OutlinedButton.icon(
                            key: const Key('donor-pick-date'),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () => _pickDate(context, date),
                            label: Text(l10n.donorPickDate),
                        ),
                        const SizedBox(width: 12),
                        // Equally weighted with the picker, per FR-DONOR-001: never having
                        // donated is a normal answer, not a skipped field.
                        OutlinedButton(
                            key: const Key('donor-never-donated'),
                            onPressed: ref.read(donorSetupProvider.notifier)
                                .clearLastDonationDate,
                            child: Text(l10n.donorNeverDonated),
                        ),
                    ],
                ),
            ],
        );
    }

    Future<void> _pickDate(BuildContext context, DateTime? current) async {
        final now = DateTime.now();
        final picked = await showDatePicker(
            context: context,
            initialDate: current ?? now,
            firstDate: DateTime(now.year - 10),
            // Future dates are not selectable. The server rejects them with
            // LAST_DONATION_IN_FUTURE, and a future date would make the donor permanently
            // ineligible — better to make it unreachable than to explain the error.
            lastDate: now,
        );
        if (picked == null || !mounted) return;
        ref.read(donorSetupProvider.notifier).setLastDonationDate(picked);
    }
}
