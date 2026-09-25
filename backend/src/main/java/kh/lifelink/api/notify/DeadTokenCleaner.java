package kh.lifelink.api.notify;

import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import java.util.Collection;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Drops FCM tokens that FCM has reported dead, for both push paths.
 *
 * <p>Its own bean so the {@code REQUIRES_NEW} below is real. It used to be a package-private method
 * on {@link RequestAlertNotifier} called from inside that class, which Spring's proxy never sees —
 * the {@code @Modifying} update ran with no transaction, threw, and was swallowed into a warning, so
 * no dead token was ever cleared.
 *
 * <p>Both callers run after their own transaction has committed (or with none at all), and a
 * cleanup failure must not be able to affect what already committed. This throws; the callers
 * catch. Catching in here would leave the new transaction marked rollback-only and turn the failure
 * into an {@code UnexpectedRollbackException} on the way out anyway.
 */
@Component
class DeadTokenCleaner {

    private static final Logger log = LoggerFactory.getLogger(DeadTokenCleaner.class);

    private final PushRecipientRepository recipients;

    DeadTokenCleaner(PushRecipientRepository recipients) {
        this.recipients = recipients;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void clear(Collection<UUID> userIds) {
        if (userIds.isEmpty()) {
            return;
        }
        recipients.clearTokens(userIds);
        log.info("Cleared {} dead FCM tokens", userIds.size());
    }

    /** FCM's two answers for "this token will never work again". Anything else may be transient. */
    static boolean isDead(FirebaseMessagingException ex) {
        return ex != null
                && (ex.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
                        || ex.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT);
    }
}
