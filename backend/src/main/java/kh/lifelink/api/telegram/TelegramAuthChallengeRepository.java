package kh.lifelink.api.telegram;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelegramAuthChallengeRepository extends JpaRepository<TelegramAuthChallenge, UUID> {

    Optional<TelegramAuthChallenge> findBySessionToken(String sessionToken);
}
