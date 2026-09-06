package kh.lifelink.api.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import kh.lifelink.api.auth.dto.AuthResponse;
import kh.lifelink.api.auth.dto.FcmTokenRequest;
import kh.lifelink.api.auth.dto.ChangePasswordRequest;
import kh.lifelink.api.auth.dto.PortalLoginRequest;
import kh.lifelink.api.auth.dto.GoogleSignInRequest;
import kh.lifelink.api.common.error.ApiException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
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

    /**
     * Portal staff sign-in, and the second unauthenticated endpoint.
     *
     * <p>Rate limited per IP on the same limiter as {@code /auth/google}, for a different reason:
     * that endpoint is expensive per call, this one is guessable. Five wrong passwords a minute is
     * not a brute force.
     */
    @PostMapping("/portal/login")
    AuthResponse portalLogin(
            @Valid @RequestBody PortalLoginRequest body, HttpServletRequest request) {
        if (!rateLimiter.tryAcquire(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many sign-in attempts.");
        }
        return auth.signInWithPassword(body.username(), body.password());
    }

    /**
     * Change your own password. Authenticated, and rate limited on the same per-IP bucket as
     * sign-in: verifying the current password is exactly as guessable as signing in.
     */
    @PostMapping("/portal/password")
    ResponseEntity<Void> changePassword(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ChangePasswordRequest body,
            HttpServletRequest request) {
        if (!rateLimiter.tryAcquire(request.getRemoteAddr())) {
            throw ApiException.rateLimited("RATE_LIMITED", "Too many attempts.");
        }
        auth.changePassword(userId, body.currentPassword(), body.newPassword());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/fcm-token")
    ResponseEntity<Void> registerFcmToken(
            @AuthenticationPrincipal UUID userId, @Valid @RequestBody FcmTokenRequest body) {
        auth.registerFcmToken(userId, body.fcmToken(), body.language());
        return ResponseEntity.noContent().build();
    }

    /**
     * Sign-out. The client disposes of the session JWT itself — there is no server-side revocation
     * (ADR 0007) — but the FCM token has to be cleared here, or a signed-out device keeps receiving
     * urgent-request pushes. No body: the row cleared is the JWT subject's, on the same rule as the
     * POST above.
     */
    @DeleteMapping("/fcm-token")
    ResponseEntity<Void> clearFcmToken(@AuthenticationPrincipal UUID userId) {
        auth.clearFcmToken(userId);
        return ResponseEntity.noContent().build();
    }
}
