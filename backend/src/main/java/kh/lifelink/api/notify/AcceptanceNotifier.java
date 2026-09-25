package kh.lifelink.api.notify;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import java.util.List;
import java.util.Optional;
import kh.lifelink.api.config.FirebaseConfig;
import kh.lifelink.api.match.DonorAccepted;
import kh.lifelink.api.notify.PushRecipientRepository.RequesterRecipient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * FR-NOTIFY-003 — tells the family who posted a request that a donor accepted it. The other half of
 * {@link RequestAlertNotifier}: that one pushes donors when a request is created, this one pushes
 * the requester when a donor answers yes.
 *
 * <p><strong>After commit only.</strong> An acceptance that rolls back must not have told a family
 * that someone is coming. And like the donor alert, <strong>this never throws</strong>: the donor's
 * acceptance has already committed by the time this runs, and nothing FCM does may turn their
 * respond call into an error.
 */
@Component
public class AcceptanceNotifier {

    private static final Logger log = LoggerFactory.getLogger(AcceptanceNotifier.class);

    private final PushRecipientRepository recipients;
    private final DeadTokenCleaner deadTokens;
    private final FirebaseConfig firebase;

    AcceptanceNotifier(
            PushRecipientRepository recipients,
            DeadTokenCleaner deadTokens,
            FirebaseConfig firebase) {
        this.recipients = recipients;
        this.deadTokens = deadTokens;
        this.firebase = firebase;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDonorAccepted(DonorAccepted event) {
        try {
            notifyRequester(event);
        } catch (Exception ex) {
            // Deliberately broad. Nothing FCM does may propagate out of this class.
            log.error("Acceptance push for request {} failed", event.requestId(), ex);
        }
    }

    private void notifyRequester(DonorAccepted event) {
        if (!firebase.isAvailable()) {
            log.warn("FCM unavailable; requester of {} not told of acceptance", event.requestId());
            return;
        }

        Optional<RequesterRecipient> found = recipients.findRequester(event.requestId());
        if (found.isEmpty()) {
            // A portal-created request (staff have no token) or a requester who declined
            // notification permission. Both are normal.
            log.info("Requester of {} has no FCM token; acceptance not pushed", event.requestId());
            return;
        }
        RequesterRecipient requester = found.get();

        Message message =
                Message.builder()
                        .setToken(requester.getFcmToken())
                        .setNotification(
                                Notification.builder()
                                        .setTitle(title(requester.getLanguage()))
                                        .setBody(
                                                body(
                                                        requester.getLanguage(),
                                                        requester.getPatientBloodType(),
                                                        requester.getHospitalName()))
                                        .build())
                        // Same shape as the donor alert, so the client tells the two apart by
                        // `type` alone.
                        .putData("type", "DONOR_ACCEPTED")
                        .putData("requestId", event.requestId().toString())
                        .build();

        try {
            String messageId = FirebaseMessaging.getInstance(firebase.requireApp()).send(message);
            // FCM's id, not the token. Without a success line a silent send and a listener that
            // never ran look identical in the log.
            log.info("Acceptance push for request {} sent ({})", event.requestId(), messageId);
        } catch (FirebaseMessagingException ex) {
            if (DeadTokenCleaner.isDead(ex)) {
                clearDeadToken(requester);
            }
            // The code only. The exception text can carry a token, and a token is a credential.
            log.warn(
                    "Acceptance push for request {} failed ({})",
                    event.requestId(),
                    ex.getMessagingErrorCode());
        }
    }

    private void clearDeadToken(RequesterRecipient requester) {
        try {
            deadTokens.clear(List.of(requester.getUserId()));
        } catch (Exception ex) {
            log.warn("Could not clear dead FCM token", ex);
        }
    }

    /**
     * Blood type and hospital, as in the donor alert, and nothing about the donor — the lock screen
     * never carries a name or a phone number (TM-AUTH-001 I2). The text promises no more than the
     * app shows: the requester's view carries the accepted count, not the donor's identity, so it
     * must not say "see who is coming".
     */
    private static String title(String language) {
        return "en".equals(language)
                ? "A donor accepted your request"
                : "មានអ្នកបរិច្ចាគទទួលយកសំណើរបស់អ្នក";
    }

    private static String body(String language, String patientBloodType, String hospitalName) {
        return "en".equals(language)
                ? "%s at %s — open LifeLink to see your request"
                        .formatted(patientBloodType, hospitalName)
                : "ឈាមប្រភេទ %s នៅ %s — បើក LifeLink ដើម្បីមើលសំណើរបស់អ្នក"
                        .formatted(patientBloodType, hospitalName);
    }
}
