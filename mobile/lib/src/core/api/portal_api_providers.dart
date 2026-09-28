import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import 'functions_portal_api.dart';
import 'portal_api.dart';

part 'portal_api_providers.g.dart';

/// The `cloud_functions` instance the portal calls go through (ADR 0010). Only
/// `httpsCallableFromUrl` is used on it, so the region is irrelevant to the address — it
/// is set anyway, so a stray `httpsCallable(name)` would at least aim at Singapore rather
/// than `us-central1`. A provider rather than `FirebaseFunctions.instance` at the call
/// site, so no widget test reaches a platform channel.
@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(FirebaseFunctionsRef ref) =>
    FirebaseFunctions.instanceFor(region: 'asia-southeast1');

/// The portal's functions, at `Env.portalUrl`. Every repository that used to write
/// through a Cloud Function or a trigger-backed Firestore write calls this instead.
@Riverpod(keepAlive: true)
PortalApi portalApi(PortalApiRef ref) =>
    FunctionsPortalApi(ref.watch(firebaseFunctionsProvider), baseUrl: Env.portalUrl);
