package kh.lifelink.api.request;

import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Cambodian mobile numbers, as the Telecommunication Regulator of Cambodia allocates them:
 * https://www.trc.gov.kh/en/resources/mobile-prefixes/ (read 2026-09-25).
 *
 * <p>A number is a three-digit prefix (with its leading 0) and a subscriber part of six digits, or
 * seven for the prefixes TRC marks with an asterisk. The request's callback number is the one the
 * accepting donor dials, so a wrong one is worse than none. Mirrors {@code cambodian_phone.dart} in
 * the mobile app — change both together.
 */
final class CambodianPhone {

    private static final Set<String> SIX_DIGIT =
            Set.of(
                    "010", "011", "012", "014", "015", "016", "017", "060", "061", "066", "067",
                    "068", "069", "070", "077", "078", "081", "085", "086", "087", "089", "090",
                    "092", "093", "095", "098", "099");
    private static final Set<String> SEVEN_DIGIT =
            Set.of("018", "031", "071", "076", "088", "096", "097");
    private static final Pattern TYPED = Pattern.compile("^\\+?[0-9 .\\-()]+$");

    private CambodianPhone() {}

    /** The number as {@code +855XXXXXXXX}, or empty if it is not a Cambodian mobile. */
    static Optional<String> normalize(String input) {
        if (input == null || !TYPED.matcher(input.trim()).matches()) {
            return Optional.empty();
        }
        String digits = input.replaceAll("[^0-9]", "");
        if (digits.startsWith("00855")) {
            digits = digits.substring(5);
        } else if (digits.startsWith("855")) {
            digits = digits.substring(3);
        }
        if (!digits.startsWith("0")) {
            digits = "0" + digits;
        }
        if (digits.length() < 3) {
            return Optional.empty();
        }
        String prefix = digits.substring(0, 3);
        int subscriberLength = digits.length() - 3;
        boolean valid =
                (SIX_DIGIT.contains(prefix) && subscriberLength == 6)
                        || (SEVEN_DIGIT.contains(prefix) && subscriberLength == 7);
        return valid ? Optional.of("+855" + digits.substring(1)) : Optional.empty();
    }
}
