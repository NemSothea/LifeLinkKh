package kh.lifelink.api.telegram;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import kh.lifelink.api.auth.JwtAuthFilter;
import kh.lifelink.api.auth.JwtService;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.config.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Web-slice test: no PostgreSQL, so it passes in CI. Exists specifically to close
 * SEC-REVIEW-002's F1 — the secret-token check has to be proven at the HTTP layer, not only in a
 * unit test that never goes near the header Spring actually parses.
 */
@WebMvcTest(TelegramAuthController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, JwtService.class})
@ActiveProfiles("test")
class TelegramAuthControllerTest {

    private static final String SECRET_HEADER = "X-Telegram-Bot-Api-Secret-Token";

    @Autowired private MockMvc mockMvc;

    @MockitoBean private TelegramAuthService telegram;
    @MockitoBean private TelegramConfig config;
    @MockitoBean private TelegramRateLimiter rateLimiter;

    @Test
    void webhookIsRejectedWithoutTheCorrectSecretHeader() throws Exception {
        when(config.verifyWebhookSecret(any())).thenReturn(false);

        mockMvc.perform(
                        post("/auth/telegram/webhook")
                                .contentType("application/json")
                                .content(
                                        "{\"message\":{\"text\":\"/start tok-1\",\"chat\":{\"id\":1}}}"))
                .andExpect(status().isUnauthorized());

        verify(telegram, never()).recordOtpSent(anyString(), anyLong(), any());
    }

    @Test
    void webhookIsRejectedWithNoSecretHeaderAtAll() throws Exception {
        when(config.verifyWebhookSecret(null)).thenReturn(false);

        mockMvc.perform(
                        post("/auth/telegram/webhook")
                                .contentType("application/json")
                                .content(
                                        "{\"message\":{\"text\":\"/start tok-1\",\"chat\":{\"id\":1}}}"))
                .andExpect(status().isUnauthorized());

        verify(telegram, never()).recordOtpSent(anyString(), anyLong(), any());
    }

    @Test
    void aGenuineWebhookCallRecordsTheOtpSend() throws Exception {
        when(config.verifyWebhookSecret("real-secret")).thenReturn(true);

        mockMvc.perform(
                        post("/auth/telegram/webhook")
                                .header(SECRET_HEADER, "real-secret")
                                .contentType("application/json")
                                .content(
                                        "{\"message\":{\"text\":\"/start tok-1\","
                                                + "\"chat\":{\"id\":555},"
                                                + "\"from\":{\"first_name\":\"Sok Dara\"}}}"))
                .andExpect(status().isOk());

        verify(telegram).recordOtpSent("tok-1", 555L, "Sok Dara");
    }

    @Test
    void startIsReachableWithNoAuthentication() throws Exception {
        when(rateLimiter.tryAcquireStart(any())).thenReturn(true);
        when(telegram.start(any()))
                .thenReturn(new TelegramAuthService.TelegramSession("tok-1", "https://t.me/Bot?start=tok-1"));

        mockMvc.perform(
                        post("/auth/telegram/start")
                                .contentType("application/json")
                                .content("{\"role\":\"DONOR\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void startIsRateLimitedPerIp() throws Exception {
        when(rateLimiter.tryAcquireStart(any())).thenReturn(false);

        mockMvc.perform(
                        post("/auth/telegram/start")
                                .contentType("application/json")
                                .content("{\"role\":\"DONOR\"}"))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void verifyIsReachableWithNoAuthentication() throws Exception {
        when(rateLimiter.tryAcquireVerify(any())).thenReturn(true);
        when(telegram.verify(eq("tok-1"), eq("111111")))
                .thenReturn(
                        new AuthResponse(
                                "jwt",
                                new AuthResponse.AuthenticatedUser(
                                        java.util.UUID.randomUUID(), "DONOR", "Sok Dara", true)));

        mockMvc.perform(
                        post("/auth/telegram/verify")
                                .contentType("application/json")
                                .content("{\"sessionToken\":\"tok-1\",\"code\":\"111111\"}"))
                .andExpect(status().isOk());
    }
}
