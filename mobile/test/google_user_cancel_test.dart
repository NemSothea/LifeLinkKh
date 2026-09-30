import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lifelink_kh/src/features/auth/data/firebase_google_credentials.dart';

void main() {
    group('isUserCancel', () {
        test('a dismissed account chooser is a cancel', () {
            expect(
                isUserCancel(const GoogleSignInException(
                    code: GoogleSignInExceptionCode.canceled,
                    description: 'activity is cancelled by the user.',
                )),
                isTrue,
            );
        });

        test('a canceled with no description is a cancel', () {
            expect(
                isUserCancel(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled)),
                isTrue,
            );
        });

        test('"[16] Account reauth failed." is a failure, not a cancel', () {
            expect(
                isUserCancel(const GoogleSignInException(
                    code: GoogleSignInExceptionCode.canceled,
                    description: '[16] Account reauth failed.',
                )),
                isFalse,
            );
        });

        test('any other code is not a cancel', () {
            expect(
                isUserCancel(const GoogleSignInException(
                    code: GoogleSignInExceptionCode.clientConfigurationError,
                )),
                isFalse,
            );
        });
    });
}
