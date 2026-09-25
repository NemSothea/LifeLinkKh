/// Cambodian mobile numbers, as the Telecommunication Regulator of Cambodia allocates them:
/// https://www.trc.gov.kh/en/resources/mobile-prefixes/ (read 2026-09-25).
///
/// A number is a three-digit prefix (with its leading 0) and a subscriber part of six digits,
/// or seven for the prefixes TRC marks with an asterisk. Anything else is not a Cambodian
/// mobile, and the request form is the one place a wrong digit costs a life: the donor who
/// accepted calls it and nobody answers. Mirrors `CambodianPhone.java` on the server — change
/// both together.
abstract final class CambodianPhone {
    static const Set<String> _sixDigit = {
        '010', '011', '012', '014', '015', '016', '017', '060', '061', '066', '067', '068',
        '069', '070', '077', '078', '081', '085', '086', '087', '089', '090', '092', '093',
        '095', '098', '099',
    };
    static const Set<String> _sevenDigit = {'018', '031', '071', '076', '088', '096', '097'};

    /// The number in `+855XXXXXXXX` form, or null if [input] is not a valid Cambodian mobile.
    ///
    /// Accepts what people actually type: `012 345 678`, `012-345-678`, `+855 12 345 678`,
    /// `855012345678`, `00855 12345678`.
    static String? normalize(String input) {
        var digits = input.trim();
        if (!RegExp(r'^\+?[0-9 .\-()]+$').hasMatch(digits)) {
            return null;
        }
        digits = digits.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.startsWith('00855')) {
            digits = digits.substring(5);
        } else if (digits.startsWith('855')) {
            digits = digits.substring(3);
        }
        if (!digits.startsWith('0')) {
            digits = '0$digits';
        }
        if (digits.length < 3) {
            return null;
        }
        final prefix = digits.substring(0, 3);
        final subscriberLength = digits.length - 3;
        final valid = (_sixDigit.contains(prefix) && subscriberLength == 6) ||
            (_sevenDigit.contains(prefix) && subscriberLength == 7);
        return valid ? '+855${digits.substring(1)}' : null;
    }

    static bool isValid(String input) => normalize(input) != null;
}
