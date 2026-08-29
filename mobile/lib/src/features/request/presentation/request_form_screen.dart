import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/error/result.dart';
import '../../donor/presentation/blood_type_grid.dart';
import '../application/request_form_controller.dart';
import '../application/request_providers.dart';
import 'hospital_dropdown.dart';
import 'request_detail_screen.dart';
import 'urgency_selector.dart';

/// `FR-REQUEST-001` — the one-minute urgent-request form.
///
/// One screen, not a wizard, per the prototype: donor setup is filled in once,
/// calm; this is filled in once, frightened, and a family that changes nothing
/// still submits something valid (defaults: 1 unit, URGENT).
class RequestFormScreen extends ConsumerStatefulWidget {
    const RequestFormScreen({super.key});

    static const String path = '/requests/new';

    @override
    ConsumerState<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends ConsumerState<RequestFormScreen> {
    final TextEditingController _contactName = TextEditingController();
    final TextEditingController _contactPhone = TextEditingController();
    bool _isSending = false;
    bool _sendFailed = false;

    @override
    void dispose() {
        _contactName.dispose();
        _contactPhone.dispose();
        super.dispose();
    }

    Future<void> _confirmAndSend() async {
        final l10n = AppLocalizations.of(context)!;
        final draft = ref.read(requestFormControllerProvider);

        final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                title: Text(l10n.requestConfirmTitle),
                content: Text(
                    l10n.requestConfirmCompat(draft.patientBloodType?.wireValue ?? ''),
                ),
                actions: [
                    TextButton(
                        key: const Key('request-confirm-edit'),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l10n.requestConfirmEdit),
                    ),
                    FilledButton(
                        key: const Key('request-confirm-send'),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.requestConfirmSend),
                    ),
                ],
            ),
        );
        if (confirmed != true || !mounted) return;

        setState(() {
            _isSending = true;
            _sendFailed = false;
        });
        final result = await ref.read(myRequestsControllerProvider.notifier).create(draft);
        if (!mounted) return;
        switch (result) {
            case Success(value: final created):
                context.pushReplacement(RequestDetailScreen.routeFor(created.id));
            case Failed():
                setState(() {
                    _isSending = false;
                    _sendFailed = true;
                });
        }
    }

    @override
    Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final draft = ref.watch(requestFormControllerProvider);
        final controller = ref.read(requestFormControllerProvider.notifier);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.requestFormTitle)),
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                                l10n.requestPatientBloodTypeLabel,
                                style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            BloodTypeGrid(
                                selected: draft.patientBloodType,
                                onSelected: controller.setBloodType,
                            ),
                            const SizedBox(height: 24),
                            Text(
                                l10n.requestUnitsLabel,
                                style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            // Bordered like every other field on this form (BloodTypeGrid's
                            // tiles, HospitalDropdown) — previously a bare Row that floated
                            // disconnected from the controls around it.
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                    borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        IconButton(
                                            key: const Key('request-units-decrement'),
                                            icon: const Icon(Icons.remove_circle_outline),
                                            onPressed: draft.unitsNeeded > 1
                                                ? () => controller.setUnits(draft.unitsNeeded - 1)
                                                : null,
                                        ),
                                        SizedBox(
                                            width: 32,
                                            child: Text(
                                                '${draft.unitsNeeded}',
                                                key: const Key('request-units-value'),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.titleLarge,
                                            ),
                                        ),
                                        IconButton(
                                            key: const Key('request-units-increment'),
                                            icon: const Icon(Icons.add_circle_outline),
                                            onPressed: () =>
                                                controller.setUnits(draft.unitsNeeded + 1),
                                        ),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 24),
                            HospitalDropdown(
                                selectedId: draft.hospitalId,
                                onSelected: controller.setHospital,
                            ),
                            const SizedBox(height: 24),
                            Text(
                                l10n.requestUrgencyLabel,
                                style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            UrgencySelector(
                                selected: draft.urgency,
                                onSelected: controller.setUrgency,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                                key: const Key('request-contact-name'),
                                controller: _contactName,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                    labelText: l10n.requestContactNameLabel,
                                ),
                                onChanged: controller.setContactName,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                                key: const Key('request-contact-phone'),
                                controller: _contactPhone,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                    labelText: l10n.requestContactPhoneLabel,
                                ),
                                onChanged: controller.setContactPhone,
                            ),
                            const SizedBox(height: 24),
                            if (_sendFailed)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                        l10n.requestCreateFailed,
                                        key: const Key('request-send-failed'),
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                        ),
                                    ),
                                ),
                            SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    key: const Key('request-send'),
                                    onPressed: !draft.isComplete || _isSending
                                        ? null
                                        : _confirmAndSend,
                                    child: Text(
                                        _isSending ? l10n.requestCreating : l10n.requestSendCta,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
