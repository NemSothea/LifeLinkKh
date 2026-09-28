# Architecture — LifeLink KH

```
            Firebase (lifelinkkh, asia-southeast1)
     ┌──────────────────────────────────────────────┐
     │  Firestore + Security Rules   Firebase Auth   │
     │  FCM                                          │
     └──────────────────────────────────────────────┘
          ^  Firebase SDK (reads)     ^  REST (admin ID token) + Admin SDK (the functions)
          |                           |
     Flutter app ──── POST /api/functions/{name} ────> Next.js web portal, Vercel sin1
  (donors/requesters)   createRequest · respondToMatch    (public board + admin +
     -> sideloaded APK  deleteAccount                      reviewRequest · confirmDonation)
```

- **Auth:** Firebase Auth. Google Sign-In in the app; the Firebase ID token is the session (ADR 0009
  replaced ADR 0007's own JWT). Roles: DONOR and REQUESTER in the app, ADMIN on the portal
  (DEC-014) — ADMIN is a custom claim plus an `admins/{uid}` record, and the rules check both. The
  portal admin signs in with email + password; the username maps to `{username}@portal.lifelink.invalid`.
- **Data and access:** Cloud Firestore; `firebase/firestore.rules` is the only thing between a
  client and the data, with one emulator test per rule. Model: [`firestore-data-model.md`](firestore-data-model.md).
- **Server logic — the portal's functions ([ADR 0010](adr/0010-portal-functions-replace-cloud-functions.md)):**
  `frontend/src/server/`, run on the Next server with the Admin SDK, called through
  `POST /api/functions/{name}` by the app (`createRequest`, `respondToMatch`, `deleteAccount`) and
  in-process by the portal's own Server Actions (`reviewRequest`, `confirmDonation`). The caller's
  Firebase ID token is verified before a handler runs. The rules refuse every client the writes
  these handlers make. There are no Cloud Functions and no triggers.
- **Matching:** inside `reviewRequest` on Approve (DEC-015): ABO/Rh-compatible + eligible +
  available donors within 10 km, ranked by distance, at most 25 (ADR 0004, 0003, 0008), one match
  document per notified donor. `matchedAt` is claimed in a transaction, so a retry alerts nobody twice.
- **Notifications:** FCM push from the portal's server — the alert to matched donors, the
  requester's approved / rejected / "donor accepted" notices. Scheduled eligibility reminders are
  deferred (DEC-004) — the 56-day status is shown in-app instead.
- **Portal:** Next.js Server Components; every Firestore read goes over REST from the Next server
  with the admin's ID token from an httpOnly cookie. The one credential on the server is the
  service account the functions use (`FIREBASE_SERVICE_ACCOUNT`), read in one file.
- **Local dev:** the Firebase Emulator Suite (`cd firebase && npm run emulators:app`, Firestore +
  Auth); the portal pointed at it, and the Flutter app pointed at both (`FIRESTORE_EMULATOR`,
  `PORTAL_URL`). No Docker.
- **CI:** GitHub Actions, owned by Tech Lead — jobs `firebase`, `web`, `mobile`. No infra role.
  Runbooks: [`local-development.md`](local-development.md) (local stack) +
  [`deploy-runbook.md`](deploy-runbook.md) (signed AAB, Play Store internal testing).
- **Secrets:** no service-account key in the repo. One on Vercel, as the `FIREBASE_SERVICE_ACCOUNT`
  environment variable, for the functions; one in `secrets/` (gitignored) on a laptop for seeding
  the real project. No SMS provider.

See ADR 0001 for the original stack decision, ADR 0002 for the auth decision,
[ADR 0009](adr/0009-firebase-replaces-spring-boot-and-postgres.md) for the move to Firebase, which
supersedes ADR 0001's backend and database rows, and
[ADR 0010](adr/0010-portal-functions-replace-cloud-functions.md) for moving the server logic from
Cloud Functions into the portal.
