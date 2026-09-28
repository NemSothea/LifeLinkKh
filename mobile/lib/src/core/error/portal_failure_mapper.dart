import '../api/portal_api.dart';
import 'failure.dart';

/// Translates a portal function's refusal into a domain [Failure] (ADR 0010). It lives in
/// `core/` because every repository that calls the portal would otherwise write this switch
/// again — the same reason `firestore_failure_mapper.dart` exists.
///
/// The server's `details.code` ([PortalCallException.reason]) becomes the failure's `code`
/// where the failure has one, so a screen switches on `ALREADY_RESPONDED` or `RATE_LIMITED`
/// and never on the message beside it.
Failure failureFromPortalCall(PortalCallException error) => switch (error.code) {
    'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
    'unauthenticated' => const UnauthorizedFailure(),
    'permission-denied' => ForbiddenFailure(code: error.reason ?? 'PERMISSION_DENIED'),
    'not-found' => const NotFoundFailure(),
    // What the request wanted has already happened, or can no longer happen.
    'already-exists' || 'aborted' || 'failed-precondition' =>
        ConflictFailure(code: error.reason ?? 'CONFLICT'),
    'invalid-argument' || 'out-of-range' =>
        ValidationFailure(code: error.reason ?? 'INVALID_ARGUMENT'),
    'resource-exhausted' => const RateLimitedFailure(),
    'internal' || 'unknown' || 'data-loss' => const ServerFailure(),
    _ => UnknownFailure(message: 'portal ${error.code}'),
};
