import 'dart:async';

import 'package:lifelink_kh/src/core/error/failure.dart';
import 'package:lifelink_kh/src/core/error/result.dart';
import 'package:lifelink_kh/src/core/location/location_service.dart';
import 'package:lifelink_kh/src/features/account/domain/account_deletion.dart';
import 'package:lifelink_kh/src/features/account/domain/account_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_repository.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_session.dart';
import 'package:lifelink_kh/src/features/auth/domain/auth_user.dart';
import 'package:lifelink_kh/src/features/auth/domain/facebook_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/google_credentials.dart';
import 'package:lifelink_kh/src/features/auth/domain/reauthentication.dart';
import 'package:lifelink_kh/src/features/auth/domain/session_store.dart';
import 'package:lifelink_kh/src/features/auth/domain/user_role.dart';
import 'package:lifelink_kh/src/features/notify/domain/fcm_token_repository.dart';
import 'package:lifelink_kh/src/features/donor/domain/blood_type.dart';
import 'package:lifelink_kh/src/features/donor/domain/district.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_profile_draft.dart';
import 'package:lifelink_kh/src/features/donor/domain/donor_repository.dart';
import 'package:lifelink_kh/src/features/donor/domain/eligibility.dart';
import 'package:lifelink_kh/src/features/notify/domain/push_token_source.dart';

/// Fakes at every seam the M3 auth flow crosses, so a widget test drives the real
/// `AuthService`, the real controller and the real router with no Firebase, no keystore and
/// no network.
///
/// Shared rather than per-file because the sign-in screen test and the router test need the
/// same set, and two copies would drift.
/// The Firebase uid [testSession] belongs to, and the one [FakeGoogleCredentials] reports
/// as signed in — session restore only keeps a session the Firebase user matches.
const String testUid = '11111111-1111-1111-1111-111111111111';

AuthSession testSession({String token = 'jwt-1', bool isNewAccount = false}) => AuthSession(
    token: token,
    user: AuthUser(
        id: testUid,
        role: UserRole.donor,
        displayName: 'Sothea',
        isNewAccount: isNewAccount,
    ),
);

final class FakeAuthRepository implements AuthRepository {
    Failure? failure;
    int exchangeCount = 0;

    @override
    Future<Result<AuthSession>> exchangeGoogleToken({
        required String idToken,
        required UserRole role,
    }) async {
        exchangeCount++;
        final failure = this.failure;
        if (failure != null) return Failed(failure);
        return Success(testSession());
    }
}

final class FakeSessionStore implements SessionStore {
    FakeSessionStore([this._session]);

    AuthSession? _session;

    AuthSession? get stored => _session;

    @override
    Future<AuthSession?> read() async => _session;

    @override
    Future<void> write(AuthSession session) async => _session = session;

    @override
    Future<void> clear() async => _session = null;
}

final class FakeGoogleCredentials implements GoogleCredentials {
    /// `null` models a dismissed account chooser.
    String? interactiveToken = 'firebase-id-token';

    /// The Firebase user on this device. `null` models Firebase signed out underneath a
    /// stored session.
    String? uid = testUid;
    bool signedOut = false;

    @override
    Future<String?> signIn() async => interactiveToken;

    @override
    Future<String?> currentUid() async => uid;

    @override
    Future<void> signOut() async {
        signedOut = true;
        uid = null;
    }

    /// Which provider the Firebase user came from — decides which fake is asked to
    /// re-authenticate before an account deletion.
    SignInProvider? provider = SignInProvider.google;

    /// Answers for successive [reauthenticate] calls, in order; once exhausted, every
    /// further call is [Reauthentication.confirmed]. A queue rather than one value because
    /// the deletion retry re-authenticates twice and a test may want the two to differ.
    final List<Reauthentication> reauthOutcomes = [];
    bool throwOnReauth = false;
    int reauthCount = 0;

    @override
    Future<SignInProvider?> currentProvider() async => provider;

    @override
    Future<Reauthentication> reauthenticate() async {
        reauthCount++;
        if (throwOnReauth) throw Exception('platform channel died');
        return reauthOutcomes.isEmpty ? Reauthentication.confirmed : reauthOutcomes.removeAt(0);
    }
}

final class FakeFacebookCredentials implements FacebookCredentials {
    /// `null` models a dismissed Facebook login dialog.
    String? interactiveToken = 'firebase-id-token';

    /// Same queue as `FakeGoogleCredentials.reauthOutcomes`.
    final List<Reauthentication> reauthOutcomes = [];
    int reauthCount = 0;

    @override
    Future<String?> signIn() async => interactiveToken;

    @override
    Future<Reauthentication> reauthenticate() async {
        reauthCount++;
        return reauthOutcomes.isEmpty ? Reauthentication.confirmed : reauthOutcomes.removeAt(0);
    }
}

/// The `deleteAccount` callable, scripted. [results] answer successive calls in order;
/// once exhausted, every call succeeds.
final class FakeAccountRepository implements AccountRepository {
    final List<Result<AccountDeletion>> results = [];
    int calls = 0;

    static const AccountDeletion deletion = AccountDeletion(
        requestsClosed: 1,
        acceptancesWithdrawn: 2,
        recordsAnonymised: 5,
    );

    @override
    Future<Result<AccountDeletion>> deleteAccount() async {
        calls++;
        return results.isEmpty ? const Success(deletion) : results.removeAt(0);
    }
}

final class FakeFcmTokenRepository implements FcmTokenRepository {
    final List<String> registered = [];

    /// Recorded alongside the token because the language is what decides which language
    /// an urgent-request alert arrives in — a test that only checks the token cannot
    /// tell a donor who gets English alerts from one who gets Khmer.
    final List<String?> registeredLanguages = [];
    int clearCount = 0;

    @override
    Future<Result<void>> register(String fcmToken, {String? language}) async {
        registered.add(fcmToken);
        registeredLanguages.add(language);
        return const Success(null);
    }

    @override
    Future<Result<void>> clear() async {
        clearCount++;
        return const Success(null);
    }
}

final class FakePushTokenSource implements PushTokenSource {
    String? token = 'fcm-token-1';
    bool permissionGranted = true;
    final StreamController<String> refreshes = StreamController<String>.broadcast();

    @override
    Future<bool> requestPermission() async => permissionGranted;

    @override
    Future<String?> currentToken() async => token;

    @override
    Stream<String> tokenRefreshes() => refreshes.stream;
}

/// A donor profile with a live cooldown, so eligibility rendering has both numbers to show.
DonorProfile testProfile({
    bool isAvailable = true,
    bool isEligible = false,
    DateTime? lastDonationDate,
}) => DonorProfile(
    id: '22222222-2222-2222-2222-222222222222',
    fullName: 'Nem Sothea',
    bloodType: BloodType.oNegative,
    districtCode: '1204',
    districtNameKm: 'ទួលគោក',
    districtNameEn: 'Tuol Kouk',
    lastDonationDate: lastDonationDate ?? DateTime(2026, 6, 14),
    isAvailable: isAvailable,
    eligibility: isEligible
        ? const Eligibility(isEligible: true)
        : Eligibility(
            isEligible: false,
            daysRemaining: 12,
            eligibleOn: DateTime(2026, 8, 30),
        ),
);

final class FakeDonorRepository implements DonorRepository {
    /// `null` is a real answer — a 404, which is where every donor starts.
    DonorProfile? profile;

    Failure? profileFailure;
    Failure? saveFailure;
    Failure? districtsFailure;

    final List<DonorProfileDraft> saves = [];

    @override
    Future<Result<DonorProfile?>> fetchProfile() async {
        final failure = profileFailure;
        if (failure != null) return Failed(failure);
        return Success(profile);
    }

    @override
    Future<Result<DonorProfile>> saveProfile(DonorProfileDraft draft) async {
        saves.add(draft);
        final failure = saveFailure;
        if (failure != null) return Failed(failure);
        final saved = testProfile(isAvailable: draft.isAvailable);
        profile = saved;
        return Success(saved);
    }

    @override
    Future<Result<List<District>>> fetchDistricts() async {
        final failure = districtsFailure;
        if (failure != null) return Failed(failure);
        // Khmer-alphabetical, as the server sends it.
        return const Success([
            District(code: '1201', nameKm: 'ចំការមន', nameEn: 'Chamkar Mon'),
            District(code: '1204', nameKm: 'ទួលគោក', nameEn: 'Tuol Kouk'),
        ]);
    }
}

/// `fix` is read fresh on every call, so a test can flip from a decline to a fix (or back)
/// between taps without rebuilding the fake.
final class FakeLocationService implements LocationService {
    FakeLocationService({this.fix});

    LocationFix? fix;

    @override
    Future<LocationFix?> currentFix() async => fix;
}
