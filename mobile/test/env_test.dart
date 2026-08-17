import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/config/env.dart';

void main() {
    // Tests run without --dart-define, so this is the unconfigured case. A silent
    // default here would let the app ship pointing at nothing.
    test('apiBaseUrl throws a clear error when API_BASE_URL is unset', () {
        expect(Env.isConfigured, isFalse);
        expect(
            () => Env.apiBaseUrl,
            throwsA(
                isA<StateError>().having(
                    (e) => e.message,
                    'message',
                    contains('API_BASE_URL is not set'),
                ),
            ),
        );
    });
}
