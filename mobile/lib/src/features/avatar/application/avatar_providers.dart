import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../donor/application/donor_providers.dart';
import '../domain/avatar_spec.dart';
import '../domain/avatar_store.dart';

part 'avatar_providers.g.dart';

/// Overridden in `main.dart` with the `SharedPreferences` store. The default forgets at
/// exit, so no widget test has to stub a platform channel to build the Me tab.
@Riverpod(keepAlive: true)
AvatarStore avatarStore(AvatarStoreRef ref) => InMemoryAvatarStore();

/// The signed-in user's avatar, or null with nobody signed in.
///
/// A picked one wins; otherwise the default for the user id, which follows the donor
/// profile's sex once that has loaded. Reads the profile with `valueOrNull`, so a profile
/// still loading — or failing — shows the id's default rather than no face at all.
@Riverpod(keepAlive: true)
class AvatarController extends _$AvatarController {
    @override
    AvatarSpec? build() {
        final user = ref.watch(authControllerProvider).valueOrNull?.user;
        if (user == null) return null;
        final picked = ref.read(avatarStoreProvider).read(user.id);
        if (picked != null) return picked;
        final sex = ref.watch(donorProfileControllerProvider).valueOrNull?.sex;
        return AvatarSpec.defaultFor(user.id, sex: sex);
    }

    /// Shows the new face at once, then persists it — the same order, and for the same
    /// reason, as `LocaleController.select`.
    Future<void> pick(AvatarSpec spec) async {
        final user = ref.read(authControllerProvider).valueOrNull?.user;
        if (user == null) return;
        state = spec;
        await ref.read(avatarStoreProvider).write(user.id, spec);
    }
}
