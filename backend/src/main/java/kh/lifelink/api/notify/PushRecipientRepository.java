package kh.lifelink.api.notify;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import kh.lifelink.api.user.User;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/** The two things the alert path needs from {@code users}: where to send, and in what language. */
public interface PushRecipientRepository extends Repository<User, UUID> {

    /**
     * Donors with a usable token, for the given profile ids.
     *
     * <p>A donor with no token is simply absent from this result — that is a donor who signed in
     * but never granted notification permission, and their {@code request_matches} row still exists
     * with {@code notified_at} NULL. That distinction is why {@code alertedCount} counts rows
     * written and not pushes sent.
     */
    @Query(
            value =
                    """
                    SELECT dp.id       AS "donorProfileId",
                           u.id        AS "userId",
                           u.fcm_token AS "fcmToken",
                           u.language  AS "language"
                    FROM donor_profiles dp
                    JOIN users u ON u.id = dp.user_id
                    WHERE dp.id IN (:donorProfileIds)
                      AND u.fcm_token IS NOT NULL
                    """,
            nativeQuery = true)
    List<PushRecipient> findRecipients(@Param("donorProfileIds") Collection<UUID> donorProfileIds);

    /**
     * Drops a token FCM has told us is dead. Without this every future request pays a failed send
     * for a phone that no longer exists, and the delivery-rate metric decays for a reason nobody
     * can see in the data.
     */
    @Modifying
    @Query(value = "UPDATE users SET fcm_token = NULL WHERE id IN (:userIds)", nativeQuery = true)
    void clearTokens(@Param("userIds") Collection<UUID> userIds);

    /** Aliases are quoted in the SQL so Postgres preserves their case and these getters bind. */
    interface PushRecipient {
        UUID getDonorProfileId();

        UUID getUserId();

        String getFcmToken();

        /** {@code km} or {@code en}, from the user's profile. */
        String getLanguage();
    }
}
