import 'failure.dart';

/// `Result<T> = Success<T> | Failed<T>` (Week 6).
///
/// Repositories return this instead of throwing for anything a user can cause. A
/// thrown exception still means a bug — a `Failure` means the app worked and the
/// answer was no.
///
/// Chosen over `Either<L, R>` because the left side is always a [Failure] here, and
/// naming it removes a type parameter nobody varies.
sealed class Result<T> {
    const Result();

    /// Convenience for call sites that only branch, without binding the payload.
    bool get isSuccess => this is Success<T>;

    /// The value, or `null` on failure. Prefer a `switch` — this exists for the
    /// one-line cases where the failure is genuinely uninteresting.
    T? get valueOrNull => switch (this) {
        Success<T>(value: final value) => value,
        Failed<T>() => null,
    };
}

final class Success<T> extends Result<T> {
    const Success(this.value);

    final T value;

    @override
    String toString() => 'Success($value)';
}

final class Failed<T> extends Result<T> {
    const Failed(this.failure);

    final Failure failure;

    @override
    String toString() => 'Failed($failure)';
}
