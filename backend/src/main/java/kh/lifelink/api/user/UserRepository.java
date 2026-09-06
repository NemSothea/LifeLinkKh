package kh.lifelink.api.user;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, UUID> {

    /** The sign-in lookup on every authenticated request from M3 onward. */
    Optional<User> findByFirebaseUid(String firebaseUid);

    /** The Telegram equivalent of {@link #findByFirebaseUid}. */
    Optional<User> findByTelegramChatId(Long telegramChatId);

    /**
     * The portal sign-in lookup. Unique in the schema, so at most one row — and the caller
     * must treat an empty result exactly like a wrong password (see
     * {@code AuthService.signInWithPassword}), or the response time tells an attacker
     * which usernames exist.
     */
    Optional<User> findByUsername(String username);

    /**
     * Active accounts of a role. Used for one thing only: refusing to remove the last ADMIN, which
     * would leave the portal with nobody able to grant access and no reset path to recover through.
     */
    long countByRoleAndDeactivatedAtIsNull(String role);

    /**
     * Self-service accounts an ADMIN can promote to HOSPITAL/ADMIN — never an existing staff row.
     */
    List<User> findByRoleInOrderByDisplayNameAsc(List<String> roles);
}
