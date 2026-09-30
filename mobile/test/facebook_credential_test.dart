import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/features/auth/data/firebase_facebook_credentials.dart';

/// iOS Limited Login hands back an OIDC ID token, Android a Graph access token. Sending
/// the first to Firebase as an access token is the bug this guards: Firebase checks it
/// against the Graph API and refuses it.
void main() {
    test('a limited (iOS) token opens an OIDC credential carrying the raw nonce', () {
        final credential = facebookCredentialFor(
            fb.LimitedToken(
                userId: '1',
                userName: 'Donor',
                userEmail: null,
                nonce: 'hashed',
                tokenString: 'id.token.jwt',
            ),
            rawNonce: 'raw-nonce',
        );

        expect(credential, isA<OAuthCredential>());
        final oauth = credential as OAuthCredential;
        expect(oauth.providerId, 'facebook.com');
        expect(oauth.idToken, 'id.token.jwt');
        expect(oauth.rawNonce, 'raw-nonce');
        expect(oauth.accessToken, isNull);
    });

    test('a classic (Android) token opens a Facebook access-token credential', () {
        final credential = facebookCredentialFor(
            fb.ClassicToken(
                declinedPermissions: const [],
                grantedPermissions: const ['public_profile'],
                userId: '1',
                expires: DateTime(2030),
                tokenString: 'graph-access-token',
                applicationId: '1538785524224504',
            ),
            rawNonce: 'unused',
        );

        final oauth = credential as OAuthCredential;
        expect(oauth.providerId, 'facebook.com');
        expect(oauth.accessToken, 'graph-access-token');
        expect(oauth.idToken, isNull);
    });
}
