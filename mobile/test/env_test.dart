import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/config/env.dart';

/// Where the app sends its ID token (SEC-REVIEW-003 F-15). A debug build keeps the demo's
/// clear-text laptop portal; a release build never posts a token over http.
void main() {
    test('an https PORTAL_URL is used as given', () {
        expect(
            Env.portalUrlFrom('https://staging.example', allowHttp: false),
            'https://staging.example',
        );
    });

    test('an http PORTAL_URL works in a debug build — the local demo', () {
        expect(
            Env.portalUrlFrom('http://10.0.2.2:3000', allowHttp: true),
            'http://10.0.2.2:3000',
        );
    });

    test('an http PORTAL_URL in a release build falls back to the deployed portal', () {
        expect(Env.portalUrlFrom('http://10.0.2.2:3000', allowHttp: false), Env.defaultPortalUrl);
    });

    test('empty or not a web URL is the deployed portal', () {
        for (final raw in ['', '   ', 'ftp://host', '10.0.2.2:3000', 'https://']) {
            expect(Env.portalUrlFrom(raw, allowHttp: true), Env.defaultPortalUrl, reason: raw);
        }
    });

    test('with no PORTAL_URL defined, the deployed portal', () {
        expect(Env.portalUrl, Env.defaultPortalUrl);
    });
}
