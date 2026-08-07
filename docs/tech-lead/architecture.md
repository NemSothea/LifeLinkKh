# Architecture — LifeLink KH

```
                 Spring Boot API  ──>  PostgreSQL (Flyway)
                     ^        ^
        REST/HTTPS   |        |   REST/HTTPS
        Flutter app -+        +- Next.js web portal
     (donors/patients)          (hospitals/admin)
      -> Play Store
```

- **Auth:** Google Sign-In (Firebase) → backend verifies the Google ID token → own JWT bearer tokens;
  RBAC roles: donor, requester, hospital, admin. Phone number is an unverified profile field.
- **Matching:** server computes ABO/Rh-compatible + eligible + available donors ranked by distance.
- **Notifications:** FCM push to matched donors; scheduled eligibility reminders.
- **Infra:** docker-compose (postgres, backend, web); Flutter runs on device/emulator.
- **Secrets:** Firebase (Auth + FCM) and Maps keys via env — never committed (see docs/security).
  No SMS provider.

See ADR 0001 for the stack decision, and ADR 0002 for the auth decision (which supersedes ADR 0001's
auth clause).
