package kh.lifelink.api.user;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, UUID> {

    /** The sign-in lookup on every authenticated request from M3 onward. */
    Optional<User> findByFirebaseUid(String firebaseUid);
}
