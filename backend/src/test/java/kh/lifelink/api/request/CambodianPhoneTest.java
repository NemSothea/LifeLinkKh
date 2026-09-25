package kh.lifelink.api.request;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class CambodianPhoneTest {

    @ParameterizedTest
    @ValueSource(
            strings = {
                "012345678",
                "012 345 678",
                "012-345-678",
                "+855 12 345 678",
                "+85512345678",
                "855012345678",
                "00855 12345678"
            })
    void acceptsASixDigitPrefixHoweverTyped(String input) {
        assertThat(CambodianPhone.normalize(input)).contains("+85512345678");
    }

    @ParameterizedTest
    @ValueSource(strings = {"097 123 4567", "0971234567", "+855 97 123 4567"})
    void acceptsAStarredPrefixWithSevenDigits(String input) {
        assertThat(CambodianPhone.normalize(input)).contains("+855971234567");
    }

    @ParameterizedTest
    @ValueSource(
            strings = {
                "",
                "01",
                "097 123 456", // starred prefix, six digits
                "0123456789", // six-digit prefix, seven digits
                "023 123 456", // Phnom Penh landline
                "013 123 456", // not allocated to mobile
                "012 ABC 678"
            })
    void rejectsAnythingElse(String input) {
        assertThat(CambodianPhone.normalize(input)).isEmpty();
    }
}
