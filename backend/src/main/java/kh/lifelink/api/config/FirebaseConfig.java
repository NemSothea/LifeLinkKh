package kh.lifelink.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import kh.lifelink.api.common.error.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Firebase Admin SDK initialisation, split into two things that are often conflated.
 *
 * <p><strong>Configuration we know now</strong> — {@code FIREBASE_PROJECT_ID} is the value pinned
 * as {@code aud} and {@code iss}. It has no default. A missing one fails startup through Spring's
 * placeholder resolution, exactly as {@code SPRING_DATASOURCE_USERNAME} already does. A development
 * default here would be a control that silently disables itself in the environment where it
 * matters.
 *
 * <p><strong>A credential file that does not exist yet</strong> — the service-account JSON. The
 * Firebase project has not been created (docs/scope.md flags it as external lead time blocking M3),
 * so the SDK cannot initialise. Rather than refuse to boot the whole API for that, initialisation
 * is attempted once and its outcome recorded. {@code POST /auth/google} then answers **503
 * AUTH_PROVIDER_UNCONFIGURED** while every other endpoint works normally.
 *
 * <p>There is deliberately no stub verifier in main code. A verifier that accepts tokens when
 * unconfigured is the footgun this class exists to avoid; mocking belongs in tests.
 */
@Component
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    private final String projectId;
    private FirebaseApp app;

    FirebaseConfig(@Value("${lifelink.firebase.project-id}") String projectId) {
        this.projectId = projectId;
    }

    @PostConstruct
    void initialise() {
        if (projectId.isBlank()) {
            throw new IllegalStateException(
                    "lifelink.firebase.project-id is blank. It is the aud/iss value pinned during"
                            + " token verification and must be set explicitly.");
        }
        try {
            FirebaseOptions options =
                    FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.getApplicationDefault())
                            .setProjectId(projectId)
                            .build();
            this.app =
                    FirebaseApp.getApps().isEmpty()
                            ? FirebaseApp.initializeApp(options)
                            : FirebaseApp.getInstance();
            log.info("Firebase Admin SDK initialised for project {}", projectId);
        } catch (IOException | IllegalStateException ex) {
            // No credentials available. Expected until the Firebase project exists.
            this.app = null;
            log.warn(
                    "Firebase Admin SDK not initialised ({}). POST /auth/google will answer 503"
                            + " until GOOGLE_APPLICATION_CREDENTIALS points at a service account.",
                    ex.getClass().getSimpleName());
        }
    }

    public boolean isAvailable() {
        return app != null;
    }

    public FirebaseApp requireApp() {
        if (app == null) {
            throw ApiException.providerUnavailable(
                    "AUTH_PROVIDER_UNCONFIGURED", "Sign-in is unavailable.");
        }
        return app;
    }

    public String getProjectId() {
        return projectId;
    }
}
