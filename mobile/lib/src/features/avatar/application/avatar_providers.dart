import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../donor/application/donor_providers.dart';
import '../domain/avatar_account.dart';
import '../domain/avatar_spec.dart';
import '../domain/avatar_store.dart';

part 'avatar_providers.g.dart';

/// Overridden in `main.dart` with the `SharedPreferences` store. The default forgets at
/// exit, so no widget test has to stub a platform channel to build the Me tab.
@Riverpod(keepAlive: true)
AvatarStore avatarStore(AvatarStoreRef ref) => InMemoryAvatarStore();

/// Overridden in `main.dart` with the Firestore one. A plain `Provider`, not generated, so no
/// `build_runner` run is needed for it.
final avatarAccountProvider = Provider<AvatarAccount>((ref) => const NoAvatarAccount());

/// The signed-in user's avatar, or null with nobody signed in.
///
/// A picked one wins; otherwise the default for the user id, which follows the donor
/// profile's sex once that has loaded. Reads the profile with `valueOrNull`, so a profile
/// still loading — or failing — shows the id's default rather than no face at all.
@Riverpod(keepAlive: true)
class AvatarController extends _$AvatarController {
    /// Who the last build was for — checked after an account read instead of `ref`, which
    /// Riverpod refuses between a dependency changing and the rebuild it causes.
    String? _userId;

    @override
    AvatarSpec? build() {
        final user = ref.watch(authControllerProvider).valueOrNull?.user;
        _userId = user?.id;
        if (user == null) return null;
        final picked = ref.read(avatarStoreProvider).read(user.id);
        if (picked != null) return picked;
        // Nothing picked on this phone — maybe a reinstall, or a new phone. The account may
        // remember a pick; the default face shows until it answers.
        unawaited(_restoreFromAccount(user.id));
        final sex = ref.watch(donorProfileControllerProvider).valueOrNull?.sex;
        return AvatarSpec.defaultFor(user.id, sex: sex);
    }

    /// Shows the new face at once, then persists it — the same order, and for the same
    /// reason, as `LocaleController.select`.
    Future<void> pick(AvatarSpec spec) async {
        final user = ref.read(authControllerProvider).valueOrNull?.user;
        if (user == null) return;
        // Read before the first await, for the reason `_userId` gives.
        final account = ref.read(avatarAccountProvider);
        state = spec;
        await ref.read(avatarStoreProvider).write(user.id, spec);
        // Not awaited: Firestore resolves a write only when the server acknowledges it, and
        // offline that is never — the pick is already shown and kept on the phone.
        unawaited(account.save(user.id, spec));
    }

    Future<void> _restoreFromAccount(String userId) async {
        final store = ref.read(avatarStoreProvider);
        final remembered = await ref.read(avatarAccountProvider).fetch(userId);
        if (remembered == null) return;
        // Only if it still applies: the user may have signed out, or picked a face on this
        // phone, while the read was in flight.
        if (_userId != userId || store.read(userId) != null) return;
        await store.write(userId, remembered);
        state = remembered;
    }
}
