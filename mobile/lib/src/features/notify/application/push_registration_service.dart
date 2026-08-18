// ignore_for_file: prefer_initializing_formals — the fields are private and Dart
// forbids a named parameter that starts with an underscore, so the lint's fix does not
// compile here.
import 'dart:async';

import '../../../core/error/result.dart';
import '../domain/fcm_token_repository.dart';
import '../domain/push_token_source.dart';

/// Keeps the backend's copy of this device's FCM token current.
///
/// M3 owns registration even though the push itself is M4 (DEC-002): a request alert at
/// M4 has nowhere to go if no tokens were collected before it.
///
/// Stateless (S2) — [watchTokenRefreshes] hands the subscription back rather than holding
/// it, so whoever owns the lifetime is the one that cancels it.
final class PushRegistrationService {
    const PushRegistrationService({
        required PushTokenSource source,
        required FcmTokenRepository repository,
    })  : _source = source,
          _repository = repository;

    final PushTokenSource _source;
    final FcmTokenRepository _repository;

    /// Asks permission, reads the token, registers it.
    ///
    /// Returns `null` when there is no token to register — permission declined, or no Play
    /// Services. That is a distinct outcome from a failed POST, and neither is an error the
    /// caller should surface: sign-in has already succeeded by the time this runs, and a
    /// donor who cannot receive push is still registered and still matchable.
    Future<Result<void>?> registerThisDevice() async {
        await _source.requestPermission();
        final token = await _source.currentToken();
        if (token == null) return null;
        return _repository.register(token);
    }

    /// Re-registers on every rotation. The caller cancels the returned subscription on
    /// sign-out.
    StreamSubscription<String> watchTokenRefreshes() =>
        _source.tokenRefreshes().listen(_repository.register);
}
