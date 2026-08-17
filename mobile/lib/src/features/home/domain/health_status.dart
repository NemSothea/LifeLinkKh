/// What the backend reported about itself.
///
/// A value object rather than a bare `String`, for the reason Week 3 gives: the
/// domain type is what crosses every layer boundary, and a `String` crossing four
/// boundaries tells no one what it holds. `final class`, value equality, no Flutter
/// import — testable with `dart test`.
final class HealthStatus {
    const HealthStatus(this.status);

    /// The `status` field of `GET /health`, e.g. `UP`.
    final String status;

    bool get isUp => status == 'UP';

    @override
    bool operator ==(Object other) =>
        other is HealthStatus && other.status == status;

    @override
    int get hashCode => status.hashCode;

    @override
    String toString() => 'HealthStatus($status)';
}
