package kh.lifelink.api.telegram;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * The tiny slice of Telegram's own Update shape this backend reads. Telegram sends many more
 * fields; {@code @JsonIgnoreProperties(ignoreUnknown = true)} at every level is what lets this stay
 * tiny instead of modelling an API this backend doesn't otherwise touch.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
record TelegramUpdate(Message message) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Message(String text, Chat chat, From from) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    record Chat(long id) {}

    /**
     * {@code first_name} only — the same "one field, not the whole profile" restraint {@code
     * GoogleTokenVerifier} applies to {@code VerifiedIdentity}. No username, no last name.
     */
    @JsonIgnoreProperties(ignoreUnknown = true)
    record From(@JsonProperty("first_name") String firstName) {}
}
