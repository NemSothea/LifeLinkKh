import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/l10n/app_localizations.dart';
import 'package:lifelink_kh/src/features/auth/application/auth_providers.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';
import 'package:lifelink_kh/src/features/avatar/application/avatar_providers.dart';
import 'package:lifelink_kh/src/features/avatar/domain/avatar_account.dart';
import 'package:lifelink_kh/src/features/avatar/domain/avatar_spec.dart';
import 'package:lifelink_kh/src/features/avatar/domain/avatar_store.dart';
import 'package:lifelink_kh/src/features/avatar/presentation/avatar_picker_sheet.dart';
import 'package:lifelink_kh/src/features/avatar/presentation/profile_avatar.dart';
import 'package:lifelink_kh/src/features/donor/application/donor_providers.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_sex.dart';

/// The Me tab's generated avatar: the default face is stable per user, follows the donor
/// profile's sex, survives a round trip through the store, and the picker hands back the
/// face that was tapped.
void main() {
    group('AvatarSpec', () {
        test('the default face is the same for the same user every time', () {
            expect(AvatarSpec.defaultFor('user-1'), AvatarSpec.defaultFor('user-1'));
            expect(stableHash('user-1'), stableHash('user-1'));
        });

        test('the default follows the donor profile sex when there is one', () {
            expect(AvatarSpec.defaultFor('u', sex: DonorSex.male).gender, AvatarGender.male);
            expect(AvatarSpec.defaultFor('u', sex: DonorSex.female).gender, AvatarGender.female);
        });

        test('encode and decode round-trip, and garbage decodes to null', () {
            const spec = AvatarSpec(gender: AvatarGender.female, seed: 42);
            expect(AvatarSpec.decode(spec.encode()), spec);
            for (final bad in [null, '', 'x:1', 'm', 'm:abc', 'm:-3', 'm:1:2']) {
                expect(AvatarSpec.decode(bad), isNull, reason: '$bad');
            }
        });
    });

    test('the store only answers for the user who picked', () async {
        final store = InMemoryAvatarStore();
        const spec = AvatarSpec(gender: AvatarGender.male, seed: 7);
        await store.write('alice', spec);
        expect(store.read('alice'), spec);
        expect(store.read('bob'), isNull);
    });

    testWidgets('the picker returns the tapped face, in the chosen gender', (tester) async {
        const current = AvatarSpec(gender: AvatarGender.male, seed: 123);
        AvatarSpec? picked;
        await tester.pumpWidget(
            MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: Builder(
                    builder: (context) => TextButton(
                        onPressed: () async => picked = await showAvatarPicker(context, current),
                        child: const Text('open'),
                    ),
                ),
            ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileAvatar), findsNWidgets(AvatarPickerSheet.optionCount));

        await tester.tap(find.text('Female'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('avatar-shuffle')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('avatar-option-2')));
        await tester.pumpAndSettle();

        expect(picked, isNotNull);
        expect(picked!.gender, AvatarGender.female);
        expect(picked!.seed, isNot(current.seed));
        expect(find.byType(AvatarPickerSheet), findsNothing);
    });

    group('the pick on the account', () {
        const remembered = AvatarSpec(gender: AvatarGender.female, seed: 42);

        ProviderContainer container(_FakeAvatarAccount account, AvatarStore store) {
            final c = ProviderContainer(overrides: [
                authControllerProvider.overrideWith(_SignedIn.new),
                donorProfileControllerProvider.overrideWith(_NoDonorProfile.new),
                avatarStoreProvider.overrideWithValue(store),
                avatarAccountProvider.overrideWithValue(account),
            ]);
            addTearDown(c.dispose);
            return c;
        }

        test('after a reinstall the account brings the picked face back', () async {
            final account = _FakeAvatarAccount()..saved['u1'] = remembered;
            final store = InMemoryAvatarStore();
            final c = container(account, store);
            await c.read(authControllerProvider.future);
            c.listen(avatarControllerProvider, (_, _) {});

            expect(c.read(avatarControllerProvider), AvatarSpec.defaultFor('u1'));
            await pumpEventQueue();
            expect(c.read(avatarControllerProvider), remembered);
            expect(store.read('u1'), remembered, reason: 'kept on the phone from then on');
        });

        test('a pick is saved to the account as well as the phone', () async {
            final account = _FakeAvatarAccount();
            final c = container(account, InMemoryAvatarStore());
            await c.read(authControllerProvider.future);
            c.listen(avatarControllerProvider, (_, _) {});

            await c.read(avatarControllerProvider.notifier).pick(remembered);
            await pumpEventQueue();
            expect(account.saved['u1'], remembered);
        });

        test('a pick on the phone is not overwritten by a slower account read', () async {
            final account = _FakeAvatarAccount()..saved['u1'] = remembered;
            final c = container(account, InMemoryAvatarStore());
            await c.read(authControllerProvider.future);
            c.listen(avatarControllerProvider, (_, _) {});

            const fresh = AvatarSpec(gender: AvatarGender.male, seed: 7);
            await c.read(avatarControllerProvider.notifier).pick(fresh);
            await pumpEventQueue();
            expect(c.read(avatarControllerProvider), fresh);
        });
    });
}

final class _FakeAvatarAccount implements AvatarAccount {
    final Map<String, AvatarSpec> saved = {};

    @override
    Future<AvatarSpec?> fetch(String userId) async {
        await Future<void>.delayed(Duration.zero);
        return saved[userId];
    }

    @override
    Future<void> save(String userId, AvatarSpec spec) async => saved[userId] = spec;
}

class _SignedIn extends AuthController {
    @override
    Future<AuthSession?> build() async => const AuthSession(
        token: 't',
        user: AuthUser(id: 'u1', role: UserRole.donor, displayName: 'Dara', isNewAccount: false),
    );
}

class _NoDonorProfile extends DonorProfileController {
    @override
    Future<DonorProfile?> build() async => null;
}
