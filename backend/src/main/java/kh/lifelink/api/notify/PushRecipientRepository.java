package kh.lifelink.api.notify;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kh.lifelink.api.user.User;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * What the two push paths need from {@code users}: where to send, and in what language. Donor
 * alerts ({@code FR-NOTIFY-001}) look up matched donors; the acceptance push ({@code
 * FR-NOTIFY-003}) looks up the one user who created the request.
 */
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
     * The request's creator, with what the acceptance push says about the request. Empty when the
     * creator has no token — in practice every portal staff account, which sees acceptances on the
     * portal page instead.
     */
    @Query(
            value =
                    """
                    SELECT u.id                  AS "userId",
                           u.fcm_token           AS "fcmToken",
                           u.language            AS "language",
                           br.patient_blood_type AS "patientBloodType",
                           h.name                AS "hospitalName"
                    FROM blood_requests br
                    JOIN users u     ON u.id = br.created_by_user_id
                    JOIN hospitals h ON h.id = br.hospital_id
                    WHERE br.id = :requestId
                      AND u.fcm_token IS NOT NULL
                    """,
            nativeQuery = true)
    Optional<RequesterRecipient> findRequester(@Param("requestId") UUID requestId);

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

    interface RequesterRecipient {
        UUID getUserId();

        String getFcmToken();

        String getLanguage();

        String getPatientBloodType();

        String getHospitalName();
    }
}
