package kh.lifelink.api.auth;

import java.util.List;
import kh.lifelink.api.user.User;
import kh.lifelink.api.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sets the portal accounts' passwords from the environment at startup.
 *
 * <p>Until {@code V19__unseed_portal_passwords.sql} the four portal accounts carried digests of a
 * password written into a migration, so anyone who could read the repository could sign in as the
 * ADMIN that grants portal access and confirms donations. The migration made those rows
 * unopenable; this class is the other half — the only way a password gets onto one now.
 *
 * <p>Three rules it follows, each of which is the reason for a line below:
 *
 * <ul>
 *   <li><b>An unset variable sets nothing.</b> No default, no fallback, no generated password
 *       printed to a log. A portal nobody can sign in to is a smaller problem than a portal
 *       everybody can, and the warning says exactly what to do about it.
 *   <li><b>A password already in place is left alone.</b> BCrypt salts per call, so re-encoding
 *       the same password every boot would rewrite four rows on every restart for no reason and
 *       would fight an admin who changed one through the product. {@code matches} first, write
 *       only on a real change.
 *   <li><b>The value never reaches a log, an exception message or a response.</b> Counts and
 *       usernames only.
 * </ul>
 */
@Component
class PortalPasswordBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(PortalPasswordBootstrap.class);

    /**
     * Short enough to be typed at a demo, long enough not to be guessed by the people watching.
     * Refusing is deliberate: silently accepting "1234" would put a weaker password on the admin
     * than the seeded one this replaced.
     */
    private static final int MIN_LENGTH = 12;

    private static final String ADMIN_ACCOUNT = "soborey";
    private static final List<String> STAFF_ACCOUNTS = List.of("calmette", "tepi", "july");

    private final UserRepository users;
    private final PasswordEncoder passwords;
    private final String adminPassword;
    private final String staffPassword;

    PortalPasswordBootstrap(
            UserRepository users,
            PasswordEncoder passwords,
            @Value("${lifelink.portal.bootstrap.admin-password:}") String adminPassword,
            @Value("${lifelink.portal.bootstrap.staff-password:}") String staffPassword) {
        this.users = users;
        this.passwords = passwords;
        this.adminPassword = adminPassword;
        this.staffPassword = staffPassword;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        int changed = apply(adminPassword, List.of(ADMIN_ACCOUNT), "PORTAL_ADMIN_PASSWORD");
        changed += apply(staffPassword, STAFF_ACCOUNTS, "PORTAL_STAFF_PASSWORD");

        if (changed > 0) {
            log.info("portal password bootstrap: set the password on {} account(s)", changed);
        }
    }

    /** @return how many rows this actually wrote */
    private int apply(String password, List<String> usernames, String variable) {
        if (password == null || password.isBlank()) {
            log.warn(
                    "portal password bootstrap: {} is not set, so {} cannot sign in. "
                            + "Set it in .env and restart — no password is seeded any more.",
                    variable,
                    usernames);
            return 0;
        }

        if (password.length() < MIN_LENGTH) {
            log.error(
                    "portal password bootstrap: {} is shorter than {} characters and was REFUSED. "
                            + "{} still cannot sign in.",
                    variable,
                    MIN_LENGTH,
                    usernames);
            return 0;
        }

        int changed = 0;
        for (String username : usernames) {
            User user = users.findByUsername(username).orElse(null);
            if (user == null) {
                // Not an error: a deployment may simply not have that hospital's account.
                log.debug("portal password bootstrap: no account named {}", username);
                continue;
            }
            String current = user.getPasswordHash();
            if (current != null && passwords.matches(password, current)) {
                continue;
            }
            user.setPasswordHash(passwords.encode(password));
            users.save(user);
            changed++;
        }
        return changed;
    }
}
