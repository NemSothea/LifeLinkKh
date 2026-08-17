package kh.lifelink.api.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.auth.dto.FcmTokenRequest;
import kh.lifelink.api.auth.dto.GoogleSignInRequest;
import kh.lifelink.api.common.error.ApiException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService auth;
    private final SignInRateLimiter rateLimiter;

    AuthController(AuthService auth, SignInRateLimiter rateLimiter) {
        this.auth = auth;
        this.rateLimiter = rateLimiter;
    }

    /** The only unauthenticated endpoint besides {@code /health}. */
    @PostMapping("/google")
    AuthResponse signIn(@Valid @RequestBody GoogleSignInRequest body, HttpServletRequest request) {
        if (!rateLimiter.tryAcquire(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many sign-in attempts.");
        }
        return auth.signIn(body.idToken(), body.role());
    }

    @PostMapping("/fcm-token")
    ResponseEntity<Void> registerFcmToken(
            @AuthenticationPrincipal UUID userId, @Valid @RequestBody FcmTokenRequest body) {
        auth.registerFcmToken(userId, body.fcmToken());
        return ResponseEntity.noContent().build();
    }
}
