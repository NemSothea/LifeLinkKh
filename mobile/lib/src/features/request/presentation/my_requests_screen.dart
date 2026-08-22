import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/request_providers.dart';
import '../domain/blood_request.dart';
import 'request_detail_screen.dart';
import 'request_form_screen.dart';

/// `GET /requests/me` — the requester's own list, and the entry point into a new
/// request.
class MyRequestsScreen extends ConsumerWidget {
    const MyRequestsScreen({super.key});

    static const String path = '/requests';

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final l10n = AppLocalizations.of(context)!;
        final requests = ref.watch(myRequestsControllerProvider);

        return Scaffold(
            appBar: AppBar(title: Text(l10n.myRequestsTitle)),
            floatingActionButton: FloatingActionButton(
                key: const Key('my-requests-new'),
                onPressed: () => context.push(RequestFormScreen.path),
                child: const Icon(Icons.add),
            ),
            body: SafeArea(
                child: RefreshIndicator(
                    onRefresh: () => ref.refresh(myRequestsControllerProvider.future),
                    child: requests.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(key: Key('my-requests-loading')),
                        ),
                        error: (_, _) => Center(
                            child: Text(
                                l10n.myRequestsFailed,
                                key: const Key('my-requests-failed'),
                            ),
                        ),
                        data: (list) => list.isEmpty
                            ? Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                        l10n.myRequestsEmpty,
                                        key: const Key('my-requests-empty'),
                                        textAlign: TextAlign.center,
                                    ),
                                ),
                            )
                            : ListView.builder(
                                key: const Key('my-requests-list'),
                                itemCount: list.length,
                                itemBuilder: (context, index) =>
                                    _RequestTile(request: list[index]),
                            ),
                    ),
                ),
            ),
        );
    }
}

class _RequestTile extends StatelessWidget {
    const _RequestTile({required this.request});

    final BloodRequest request;

    @override
    Widget build(BuildContext context) {
        return ListTile(
            key: Key('my-request-${request.id}'),
            title: Text('${request.patientBloodType.wireValue} · ${request.hospitalName}'),
            subtitle: Text(request.status.wireValue),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RequestDetailScreen.routeFor(request.id)),
        );
    }
}
