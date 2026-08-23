package kh.lifelink.api.telegram;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * The only place the Telegram Bot API is actually called. No SDK dependency — one endpoint,
 * {@code sendMessage}, doesn't justify one.
 *
 * <p>Never logs the message body (TM-AUTH-002 I1) — for this feature that body is always the OTP
 * code.
 */
@Component
class HttpTelegramBotClient implements TelegramBotClient {

    private static final Logger log = LoggerFactory.getLogger(HttpTelegramBotClient.class);
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final TelegramConfig config;
    private final ObjectMapper json;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();

    HttpTelegramBotClient(TelegramConfig config, ObjectMapper json) {
        this.config = config;
        this.json = json;
    }

    @Override
    public void sendMessage(long chatId, String text) {
        config.requireConfigured();
        try {
            String body = json.writeValueAsString(Map.of("chat_id", chatId, "text", text));
            HttpRequest request =
                    HttpRequest.newBuilder()
                            .uri(URI.create("https://api.telegram.org/bot" + config.botToken() + "/sendMessage"))
                            .timeout(TIMEOUT)
                            .header("Content-Type", "application/json")
                            .POST(HttpRequest.BodyPublishers.ofString(body))
                            .build();
            HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                // Never the response body: Telegram echoes the request back on some 4xx errors,
                // which would put the OTP text straight into the log (TM-AUTH-002 I1).
                log.warn("Telegram sendMessage failed, status={}", response.statusCode());
            }
        } catch (Exception ex) {
            log.warn("Telegram sendMessage failed: {}", ex.getClass().getSimpleName());
        }
    }
}
