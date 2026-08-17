import 'health_status.dart';

/// The abstraction the Service depends on (Week 3, rule S4).
///
/// Abstract and in `domain/` on purpose. Nothing above `data/` may name a concrete
/// implementation, which is what makes swapping the Dio implementation for a fake — in
/// a test, or for a different transport later — a one-line change in the repository
/// provider and nowhere else.
abstract interface class HealthRepository {
    /// Throws on any transport or parse failure. Typed domain failures
    /// (`Result<T>` / sealed `Failure`) arrive with Week 6 — see the follow-ups in
    /// `docs/tech-lead/adr/0006-flutter-course-architecture.md`.
    Future<HealthStatus> fetchStatus();
}
