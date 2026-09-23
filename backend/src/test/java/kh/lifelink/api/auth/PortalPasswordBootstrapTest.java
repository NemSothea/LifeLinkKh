package kh.lifelink.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import java.util.List;
import java.util.Optional;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * The replacement for a password in a migration (V19). Every assertion here is a way the old
 * arrangement could come back: a default password, a value in a log, a weak value accepted
 * silently, or a rewrite that fights an admin who changed their own password.
 */
class PortalPasswordBootstrapTest {

    private static final String GOOD = "a-long-enough-password";

    private UserRepository users;
    private PasswordEncoder passwords;
    private ListAppender<ILoggingEvent> logs;

    @BeforeEach
    void setUp() {
        users = mock(UserRepository.class);
        passwords = new BCryptPasswordEncoder();

        logs = new ListAppender<>();
        logs.start();
        ((Logger) LoggerFactory.getLogger(PortalPasswordBootstrap.class)).addAppender(logs);
    }

    private PortalPasswordBootstrap bootstrap(String admin, String staff) {
        return new PortalPasswordBootstrap(users, passwords, admin, staff);
    }

    private User account(String username, String hash) {
        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(hash);
        when(users.findByUsername(username)).thenReturn(Optional.of(user));
        return user;
    }

    private String messages() {
        return logs.list.stream().map(ILoggingEvent::getFormattedMessage).reduce("", String::concat);
    }

    @Test
    void setsThePasswordFromTheEnvironment() {
        User admin = account("soborey", "$2a$10$unopenable-placeholder-from-V19");
        when(users.findByUsername("calmette")).thenReturn(Optional.empty());
        when(users.findByUsername("tepi")).thenReturn(Optional.empty());
        when(users.findByUsername("july")).thenReturn(Optional.empty());

        bootstrap(GOOD, "").run(null);

        assertThat(passwords.matches(GOOD, admin.getPasswordHash())).isTrue();
    }

    @Test
    void anUnsetVariableSetsNothing() {
        User admin = account("soborey", "$2a$10$unopenable-placeholder-from-V19");

        bootstrap("", "").run(null);

        assertThat(admin.getPasswordHash()).isEqualTo("$2a$10$unopenable-placeholder-from-V19");
        verify(users, never()).save(any());
        assertThat(messages()).contains("PORTAL_ADMIN_PASSWORD is not set");
    }

    /** A password short enough to read off a projector is worse than the one V19 removed. */
    @Test
    void aShortPasswordIsRefusedRatherThanAccepted() {
        User admin = account("soborey", "$2a$10$unopenable-placeholder-from-V19");

        bootstrap("short", "").run(null);

        assertThat(admin.getPasswordHash()).isEqualTo("$2a$10$unopenable-placeholder-from-V19");
        verify(users, never()).save(any());
        assertThat(messages()).contains("REFUSED");
    }

    /**
     * BCrypt salts per call, so re-encoding on every boot would rewrite four rows for nothing —
     * and would overwrite a password an admin had changed through the product back to the one in
     * the environment file.
     */
    @Test
    void aPasswordAlreadyInPlaceIsLeftAlone() {
        String existing = passwords.encode(GOOD);
        User admin = account("soborey", existing);

        bootstrap(GOOD, "").run(null);

        assertThat(admin.getPasswordHash()).isEqualTo(existing);
        verify(users, never()).save(any());
    }

    @Test
    void theStaffVariableCoversTheThreeHospitalAccounts() {
        when(users.findByUsername("soborey")).thenReturn(Optional.empty());
        List<User> staff =
                List.of(
                        account("calmette", "$2a$10$placeholder"),
                        account("tepi", "$2a$10$placeholder"),
                        account("july", "$2a$10$placeholder"));

        bootstrap("", GOOD).run(null);

        assertThat(staff).allSatisfy(u -> assertThat(passwords.matches(GOOD, u.getPasswordHash())).isTrue());
    }

    /** Each row keeps its own salt: one cracked digest must not open the other two. */
    @Test
    void eachAccountGetsItsOwnDigest() {
        when(users.findByUsername("soborey")).thenReturn(Optional.empty());
        User calmette = account("calmette", "$2a$10$placeholder");
        User tepi = account("tepi", "$2a$10$placeholder");
        User july = account("july", "$2a$10$placeholder");

        bootstrap("", GOOD).run(null);

        assertThat(List.of(calmette.getPasswordHash(), tepi.getPasswordHash(), july.getPasswordHash()))
                .doesNotHaveDuplicates();
    }

    @Test
    void theValueNeverReachesALog() {
        account("soborey", "$2a$10$placeholder");

        bootstrap(GOOD, "hunter2-hunter2-hunter2").run(null);

        assertThat(messages()).doesNotContain(GOOD).doesNotContain("hunter2");
    }

    @Test
    void aMissingAccountIsNotAnError() {
        when(users.findByUsername(any())).thenReturn(Optional.empty());

        bootstrap(GOOD, GOOD).run(null);

        verify(users, never()).save(any());
    }
}
