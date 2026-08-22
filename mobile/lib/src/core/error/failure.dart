/// Domain failures as values, not exceptions (Week 6).
///
/// `sealed` is the whole point: every subclass is declared in this file, so a
/// `switch` over a `Failure` is exhaustive and the compiler — not a code review —
/// catches the UI that forgot a variant.
///
/// Mapping happens in `data/`. Nothing above the data layer sees a `DioException`,
/// and nothing below `presentation/` decides what a failure looks like on screen.
sealed class Failure {
    const Failure({required this.message});

    /// Developer-facing detail. **Never rendered.** The screen picks its own copy per
    /// variant so it can be localised (`FR-GLOBAL-001`); a server string cannot be.
    final String message;

    @override
    String toString() => '$runtimeType($message)';
}

/// No usable connection, DNS failure, or connect/receive timeout.
final class NetworkFailure extends Failure {
    const NetworkFailure({super.message = 'network unavailable'});
}

/// 404. Distinct from an empty list — a missing donor profile is not a broken app.
final class NotFoundFailure extends Failure {
    const NotFoundFailure({super.message = 'not found'});
}

/// 401 that survived the one re-authentication attempt of ADR 0007, or a Google
/// credential that is gone for good. The only variant that routes to sign-in.
final class UnauthorizedFailure extends Failure {
    const UnauthorizedFailure({super.message = 'session could not be renewed'});
}

/// 403. A valid session that is not entitled to this specific resource — e.g.
/// `NOT_YOUR_MATCH`, `NOT_REQUEST_CREATOR`. Distinct from [UnauthorizedFailure]:
/// this is not a session problem, and must not route to sign-in.
final class ForbiddenFailure extends Failure {
    const ForbiddenFailure({
        super.message = 'not allowed on this resource',
        this.code = 'FORBIDDEN',
    });

    final String code;
}

/// 409. The request was understood but conflicts with the resource's current
/// state — `ALREADY_RESPONDED`, `REQUEST_ALREADY_CLOSED`. Retrying the same call
/// again will not help; the screen should show what already happened instead.
final class ConflictFailure extends Failure {
    const ConflictFailure({
        super.message = 'that has already happened',
        this.code = 'CONFLICT',
    });

    final String code;
}

/// 400 or 422 — the request was understood and rejected. [code] is the backend's
/// stable `error.code`, which is what the client switches on; the message beside it is
/// prose and may change without notice.
///
/// `TM-AUTH-001` E1 makes this reachable on sign-in: asking for `HOSPITAL` or `ADMIN`
/// is a 422, deliberately not a silent downgrade to `DONOR`.
final class ValidationFailure extends Failure {
    const ValidationFailure({
        super.message = 'the server rejected these values',
        this.code = 'VALIDATION_FAILED',
    });

    /// e.g. `VALIDATION_FAILED`, `CONSTRAINT_VIOLATED`, `ROLE_NOT_SELF_SERVICE`, `UNKNOWN_BLOOD_TYPE`.
    final String code;
}

/// 429. The sign-in rate limiter (`SignInRateLimiter`) is the only source in this
/// build. Its own variant because the UI must say *wait*, not *try again* — a retry
/// button on a rate limit is a button that cannot work.
final class RateLimitedFailure extends Failure {
    const RateLimitedFailure({super.message = 'too many attempts'});
}

/// 5xx. The request was fine; the backend was not. Retrying is reasonable.
final class ServerFailure extends Failure {
    const ServerFailure({super.message = 'the server failed to answer'});
}

/// Anything unclassified, including a malformed response body. Retrying is not
/// reasonable, because we do not know what happened.
final class UnknownFailure extends Failure {
    const UnknownFailure({super.message = 'something went wrong'});
}
