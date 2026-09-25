import 'package:flutter/services.dart';
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

    group('CambodianPhoneFormatter', () {
        String type(String text) => const CambodianPhoneFormatter()
            .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
            )
            .text;

        test('groups a six-digit prefix 3-3-3 and stops at nine digits', () {
            expect(type('010'), '010');
            expect(type('0105'), '010 5');
            expect(type('010552'), '010 552');
            expect(type('010552563'), '010 552 563');
            expect(type('0105525639'), '010 552 563');
        });

        test('groups a starred prefix 3-3-4', () {
            expect(type('0971234567'), '097 123 4567');
        });

        test('re-spaces a pasted or dashed number', () {
            expect(type('010-552-563'), '010 552 563');
        });

        test('leaves international forms as typed', () {
            expect(type('+855 10 552 563'), '+855 10 552 563');
            expect(type('85510552563'), '85510552563');
        });

        test('keeps the cursor after the same digit when a space is inserted', () {
            final result = const CambodianPhoneFormatter().formatEditUpdate(
                TextEditingValue.empty,
                const TextEditingValue(text: '0105', selection: TextSelection.collapsed(offset: 4)),
            );
            expect(result.selection.end, 5);
        });
    });
}
