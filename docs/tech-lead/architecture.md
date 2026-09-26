# Architecture — LifeLink KH

```
            Firebase (lifelinkkh, asia-southeast1)
     ┌──────────────────────────────────────────────┐
     │  Firestore + Security Rules   Firebase Auth   │
     │        │ triggers                             │
     │  Cloud Functions ──────────────> FCM push     │
     └──────────────────────────────────────────────┘
          ^  Firebase SDK            ^  REST (admin ID token, from the Next server)
          |                          |
     Flutter app               Next.js web portal
  (donors/requesters)        (public board + admin)
     -> Play Store
```

- **Auth:** Firebase Auth. Google Sign-In in the app; the Firebase ID token is the session (ADR 0009
  replaced ADR 0007's own JWT). Roles: DONOR and REQUESTER in the app, ADMIN on the portal
  (DEC-014) — ADMIN is a custom claim plus an `admins/{uid}` record, and the rules check both. The
  portal admin signs in with email + password; the username maps to `{username}@portal.lifelink.invalid`.
- **Data and access:** Cloud Firestore; `firebase/firestore.rules` is the only thing between a
  client and the data, with one emulator test per rule. Model: [`firestore-data-model.md`](firestore-data-model.md).
- **Matching:** the `onRequestCreated` Function computes ABO/Rh-compatible + eligible + available
  donors within 10 km, ranked by distance, at most 25 (ADR 0004, 0003, 0008), and writes one match
  document per notified donor.
- **Notifications:** FCM push from the Functions — the alert to matched donors, and the "donor
  accepted" push to the requester (`onMatchAnswered`). Scheduled eligibility reminders are deferred
  (DEC-004) — the 56-day status is shown in-app instead.
- **Portal:** Next.js Server Components; every Firestore read and the `confirmDonation` callable go
  over REST from the Next server with the admin's ID token from an httpOnly cookie. No service
  account on the web server.
- **Local dev:** the Firebase Emulator Suite (`cd firebase && npm run emulators:app`); portal and
  Flutter app pointed at it. No Docker.
- **CI:** GitHub Actions, owned by Tech Lead — jobs `firebase`, `web`, `mobile`. No infra role.
  Runbooks: [`local-development.md`](local-development.md) (local stack) +
  [`deploy-runbook.md`](deploy-runbook.md) (signed AAB, Play Store internal testing).
- **Secrets:** no service-account key in the repo or on the web server; Functions use their runtime
  identity. A key for seeding the real project from a laptop lives in `secrets/` (gitignored).
  No SMS provider.

See ADR 0001 for the original stack decision, ADR 0002 for the auth decision, and
[ADR 0009](adr/0009-firebase-replaces-spring-boot-and-postgres.md) for the move to Firebase, which
supersedes ADR 0001's backend and database rows.
