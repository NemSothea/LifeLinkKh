import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink_kh/src/core/phone/cambodian_phone.dart';

void main() {
    group('CambodianPhone.normalize', () {
        test('accepts a six-digit prefix with six subscriber digits, however typed', () {
            for (final input in [
                '012345678',
                '012 345 678',
                '012-345-678',
                '+855 12 345 678',
                '+85512345678',
                '855012345678',
                '00855 12345678',
            ]) {
                expect(CambodianPhone.normalize(input), '+85512345678', reason: input);
            }
        });

        test('accepts a starred prefix only with seven subscriber digits', () {
            expect(CambodianPhone.normalize('097 123 4567'), '+855971234567');
            expect(CambodianPhone.normalize('097 123 456'), isNull);
            expect(CambodianPhone.normalize('0181234567'), '+855181234567');
        });

        test('rejects a six-digit prefix with seven subscriber digits', () {
            expect(CambodianPhone.normalize('0123456789'), isNull);
        });

        test('rejects prefixes TRC has not allocated to mobile', () {
            expect(CambodianPhone.normalize('023 123 456'), isNull); // Phnom Penh landline
            expect(CambodianPhone.normalize('013 123 456'), isNull);
        });

        test('rejects letters, empties and fragments', () {
            expect(CambodianPhone.normalize(''), isNull);
            expect(CambodianPhone.normalize('01'), isNull);
            expect(CambodianPhone.normalize('012 ABC 678'), isNull);
        });
    });
}
