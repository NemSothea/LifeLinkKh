package kh.lifelink.api.telegram.dto;

/**
 * @param sessionToken opaque, passed back unchanged to {@code POST /auth/telegram/verify}
 * @param deepLink {@code https://t.me/<bot>?start=<sessionToken>} — opening it in the Telegram
 *     app is what the app should do next
 */
public record TelegramStartResponse(String sessionToken, String deepLink) {}
