package kh.lifelink.api.notify;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.SendResponse;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import kh.lifelink.api.config.FirebaseConfig;
import kh.lifelink.api.notify.PushRecipientRepository.PushRecipient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * FR-NOTIFY-001 — the send path. The tokens it sends to were registered at M3, which was the point
 * of moving {@code POST /auth/fcm-token} earlier (DEC-002): M4 adds a send, not a whole subsystem.
 *
 * <p><strong>This never throws.</strong> An FCM outage must not roll back a blood request. A
 * requester whose alert failed to send still has a request the hospital can see; a requester whose
 * POST returned 500 has nothing, retries, and creates a duplicate. Failure is a log line and a set
 * of donors reported as un-notified, which is exactly what {@code request_matches.notified_at}
 * being nullable is for.
 */
@Component
public class RequestAlertNotifier {

    private static final Logger log = LoggerFactory.getLogger(RequestAlertNotifier.class);

    private final PushRecipientRepository recipients;
    private final FirebaseConfig firebase;

    RequestAlertNotifier(PushRecipientRepository recipients, FirebaseConfig firebase) {
        this.recipients = recipients;
        this.firebase = firebase;
    }

    /**
     * Alerts the matched donors.
     *
     * @return the donor profile ids whose push FCM accepted — the callers stamps {@code
     *     notified_at} on exactly these. Donors with no token are never in this set, and neither
     *     are failures.
     */
    public Set<UUID> alert(
            UUID requestId,
            String patientBloodType,
            String hospitalName,
            Collection<UUID> donorProfileIds) {

        if (donorProfileIds.isEmpty()) {
            return Set.of();
        }
        if (!firebase.isAvailable()) {
            // Expected until the Firebase service account exists, and not worth failing a request
            // over — the matches are written either way.
            log.warn("FCM unavailable; {} matched donors not alerted", donorProfileIds.size());
            return Set.of();
        }

        List<PushRecipient> targets = recipients.findRecipients(donorProfileIds);
        if (targets.isEmpty()) {
            log.info("No matched donor has an FCM token; request {} alerted nobody", requestId);
            return Set.of();
        }

        Set<UUID> notified = new HashSet<>();
        List<UUID> deadTokenUsers = new ArrayList<>();

        // One multicast per language. The data payload is identical; only the visible text differs,
        // and a single message cannot carry two bodies.
        Map<String, List<PushRecipient>> byLanguage =
                targets.stream()
                        .collect(
                                Collectors.groupingBy(
                                        r -> "en".equals(r.getLanguage()) ? "en" : "km"));

        byLanguage.forEach(
                (language, group) ->
                        send(
                                requestId,
                                patientBloodType,
                                hospitalName,
                                language,
                                group,
                                notified,
                                deadTokenUsers));

        if (!deadTokenUsers.isEmpty()) {
            clearDeadTokens(deadTokenUsers);
        }
        return notified;
    }

    private void send(
            UUID requestId,
            String patientBloodType,
            String hospitalName,
            String language,
            List<PushRecipient> group,
            Set<UUID> notified,
            List<UUID> deadTokenUsers) {

        MulticastMessage message =
                MulticastMessage.builder()
                        .addAllTokens(group.stream().map(PushRecipient::getFcmToken).toList())
                        .setNotification(
                                Notification.builder()
                                        .setTitle(title(language))
                                        .setBody(body(language, patientBloodType, hospitalName))
                                        .build())
                        // The data half is what makes the notification actionable: prd.md FR-06
                        // requires that tapping it opens the request detail, and a
                        // notification-only message gives the client nothing to route on.
                        .putData("type", "REQUEST_ALERT")
                        .putData("requestId", requestId.toString())
                        .build();

        try {
            BatchResponse batch =
                    FirebaseMessaging.getInstance(firebase.requireApp())
                            .sendEachForMulticast(message);

            List<SendResponse> responses = batch.getResponses();
            for (int i = 0; i < responses.size(); i++) {
                SendResponse response = responses.get(i);
                PushRecipient recipient = group.get(i);
                if (response.isSuccessful()) {
                    notified.add(recipient.getDonorProfileId());
                } else if (isDeadToken(response)) {
                    deadTokenUsers.add(recipient.getUserId());
                }
            }
            if (batch.getFailureCount() > 0) {
                // Count only. The exception text can carry a token, and a token is a credential.
                log.warn(
                        "Request {} alert: {} of {} sends failed ({})",
                        requestId,
                        batch.getFailureCount(),
                        responses.size(),
                        language);
            }
        } catch (Exception ex) {
            // Deliberately broad. Nothing FCM does may propagate out of this class.
            log.error("Request {} alert failed entirely for language {}", requestId, language, ex);
        }
    }

    private static boolean isDeadToken(SendResponse response) {
        return response.getException() != null
                && (response.getException().getMessagingErrorCode()
                                == MessagingErrorCode.UNREGISTERED
                        || response.getException().getMessagingErrorCode()
                                == MessagingErrorCode.INVALID_ARGUMENT);
    }

    /**
     * Its own transaction. The caller's transaction has already committed the request and its
     * matches by the time we get here, and token cleanup must not be able to affect either.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    void clearDeadTokens(List<UUID> userIds) {
        try {
            recipients.clearTokens(userIds);
            log.info("Cleared {} dead FCM tokens", userIds.size());
        } catch (Exception ex) {
            log.warn("Could not clear dead FCM tokens", ex);
        }
    }

    /**
     * The visible text carries the blood type and the hospital and nothing else. A push renders on
     * a locked screen: no donor name, no phone number, no coordinate, ever (TM-AUTH-001 I2).
     *
     * <p>Chosen server-side from {@code users.language}. FR-GLOBAL-001 is an M6 client concern, but
     * a notification is rendered by the OS before the app runs, so its language cannot wait for the
     * client's locale switch.
     */
    private static String title(String language) {
        return "en".equals(language) ? "Urgent blood request" : "សំណើឈាមបន្ទាន់";
    }

    private static String body(String language, String patientBloodType, String hospitalName) {
        return "en".equals(language)
                ? "%s needed at %s".formatted(patientBloodType, hospitalName)
                : "ត្រូវការឈាមប្រភេទ %s នៅ %s".formatted(patientBloodType, hospitalName);
    }
}
