import 'package:firebase_core/firebase_core.dart';

import 'failure.dart';

/// Translates Firestore errors into domain [Failure]s — the ADR 0009 counterpart of
/// `failureFromDio`, and for the same reason it lives in `core/`: every Firestore
/// repository would otherwise write this switch again.
///
/// `permission-denied` is the Security Rules saying no. It maps to [ForbiddenFailure],
/// not [ValidationFailure], even when the rule that refused was a value check: a rule
/// cannot say which clause failed, and guessing would put the wrong copy on screen.
Failure failureFromFirebase(FirebaseException error) => switch (error.code) {
    'unavailable' || 'deadline-exceeded' => const NetworkFailure(),
    'permission-denied' => const ForbiddenFailure(code: 'PERMISSION_DENIED'),
    'unauthenticated' => const UnauthorizedFailure(),
    'not-found' => const NotFoundFailure(),
    'already-exists' || 'aborted' => const ConflictFailure(),
    'invalid-argument' || 'failed-precondition' || 'out-of-range' =>
        ValidationFailure(code: error.code.toUpperCase().replaceAll('-', '_')),
    'resource-exhausted' => const RateLimitedFailure(),
    'internal' || 'unknown' || 'data-loss' => const ServerFailure(),
    _ => UnknownFailure(message: 'firestore ${error.code}'),
};
