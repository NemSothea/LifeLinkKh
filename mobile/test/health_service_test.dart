import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/home/application/health_service.dart';
import 'package:lifelink_kh/src/features/home/domain/health_repository.dart';
import 'package:lifelink_kh/src/features/home/domain/health_status.dart';

/// Note what is missing: no `pumpWidget`, no `ProviderScope`, no Dio, no emulator.
/// That is rule S5 being cashed in — the Service imports neither Flutter nor Riverpod,
/// so it can be exercised with a plain fake and nothing else.
final class _StubRepository implements HealthRepository {
    _StubRepository(this._result);

    final Future<HealthStatus> Function() _result;
    int calls = 0;

    @override
    Future<HealthStatus> fetchStatus() {
        calls++;
        return _result();
    }
}

void main() {
    test('returns the domain type the repository produced', () async {
        final repository = _StubRepository(() async => const HealthStatus('UP'));

        final result = await HealthService(repository).check();

        // S3: a domain type crosses the boundary, never a Dio Response.
        expect(result, const HealthStatus('UP'));
        expect(result.isUp, isTrue);
        expect(repository.calls, 1);
    });

    test('a non-UP status is reported, not treated as a failure', () async {
        final repository = _StubRepository(
            () async => const HealthStatus('DEGRADED'),
        );

        final result = await HealthService(repository).check();

        expect(result.isUp, isFalse);
        expect(result.status, 'DEGRADED');
    });

    /// The Service adds no error handling of its own — a transport failure surfaces to
    /// the provider, which turns it into an `AsyncValue.error`. Typed failures replace
    /// this when Week 6 lands.
    test('propagates a repository failure rather than swallowing it', () async {
        final repository = _StubRepository(
            () async => throw Exception('connect failed'),
        );

        expect(
            () => HealthService(repository).check(),
            throwsA(isA<Exception>()),
        );
    });

    test('HealthStatus is value-equal, so identical states do not look like changes', () {
        expect(const HealthStatus('UP'), const HealthStatus('UP'));
        expect(
            const HealthStatus('UP').hashCode,
            const HealthStatus('UP').hashCode,
        );
        expect(const HealthStatus('UP'), isNot(const HealthStatus('DOWN')));
    });
}
