package kh.lifelink.api.telegram;

/**
 * Sends a message as the LifeLink bot. A deliberately thin seam, same reasoning as {@code
 * GoogleTokenVerifier} — the one place the Telegram Bot API is touched, therefore the one place
 * tests fake, and the one place to change if the HTTP client or the API version ever moves.
 */
public interface TelegramBotClient {

    /**
     * @param chatId the recipient — always one this backend learned from an already-verified
     *     webhook call (TM-AUTH-002 S1/S2), never a client-supplied value
     * @param text the message body, e.g. the OTP code
     */
    void sendMessage(long chatId, String text);
}
