# firebase/

The Firebase backend that replaces Spring Boot + PostgreSQL — ADR 0009, branch `feat/firebase-backend`.

| File | What |
|---|---|
| `firestore.rules` | Who reads and writes what. The only thing between a client and the data |
| `rules-tests/` | One emulator test per rule. A rule without a test is treated as absent |
| `firestore.indexes.json` | Composite indexes for the board, "my requests", "my matches", history |
| `firebase.json` | Emulator ports: auth 9099, firestore 8081, UI 4000 |
| `scripts/` | `metrics.mjs`, `release.mjs`, `delete-account.mjs` (an operator answering a web deletion request) |
| `seed/` | Districts and hospitals (V3, V7), same ids as Postgres. `reference-data.json` is the source. `admin.mjs`: the portal's admin account (V13's `soborey`) |

The data model and the reason behind each rule: `docs/tech-lead/firestore-data-model.md`.

```bash
cd firebase
npm install
npm run test:rules     # starts the Firestore emulator, runs vitest, stops it (needs Java 21)
npm run emulators      # emulators + UI at http://localhost:4000, for poking by hand
npm run test:seed      # seeds an emulator and checks 14 districts, 5 hospitals, no orphans
```

**There are no Cloud Functions** since [ADR 0010](../docs/tech-lead/adr/0010-portal-functions-replace-cloud-functions.md).
What they did — matching, the pushes, approve/confirm, the app's create-request / respond /
delete-account — is `frontend/src/server/`, served by the portal at `/api/functions/{name}`, with
its tests in `frontend/test/server/` (`npm run test:server`, `npm run test:server:emulator` from
`frontend/`). The rules refuse every client the writes those handlers make. On a `demo-` project,
and on the emulators without a service account, the handlers write every push to `_outbox`
instead of sending it: FCM has no emulator, and this is how a test reads exactly what a donor
would have received.

## Running the app against the emulator

The app is built for the `lifelinkkh` project, so the emulator it talks to must run under that
id — not `demo-lifelink`, which is the tests' own sandbox.

```bash
cd firebase
npm run emulators:app                     # Firestore 8081, Auth 9099 — project lifelinkkh
npm run seed:app                          # second terminal: districts + hospitals into it

cd ../frontend                            # third terminal: the portal, which the app writes through
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run dev

cd ../mobile
flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081 \
            --dart-define=PORTAL_URL=http://10.0.2.2:3000        # Android emulator
# USB phone: adb reverse tcp:8081 tcp:8081 and tcp:3000 tcp:3000, then 127.0.0.1 for both
```

Leave `FIRESTORE_EMULATOR` unset to use the real project. That needs Firestore created in the
console, `npx firebase deploy --only firestore --project lifelinkkh` for the rules and indexes,
and `npm run seed -- --project lifelinkkh` once.

## Nothing touches a backend (phase 6)

There is no Spring Boot and no Postgres any more. The app and the portal talk to Firebase for
sign-in (the Firebase ID token is the session; `users/{uid}` is the record), the donor profile and
every read. The writes a client must not make — posting a request, answering an alert, matching
and the donor alert, the "donor accepted" push, approve/reject, confirm-donation, delete-account —
are the portal's functions (ADR 0010), which the app reaches at `PORTAL_URL`. Telegram sign-in was
dropped, and the app no longer takes `API_BASE_URL`.

## Deleting an account (DEC-016)

The app's **Me → Delete account** calls the portal's `deleteAccount` with a fresh sign-in. For someone who
wrote in through the portal's `/{locale}/delete-account` page instead:

```bash
npm run delete-account -- --uid <uid>                        # emulator
npm run delete-account -- --uid <uid> --project lifelinkkh   # REAL — GOOGLE_APPLICATION_CREDENTIALS
```

Irreversible. Personal data is deleted; requests, matches and donations are kept with the uid
cleared, so the metrics stay honest. It refuses an admin account.

## Publishing an APK version (sideloaded, no Play Store)

```bash
npm run release -- --version-code 2 --version-name 1.0.1 \
    --download-url https://<portal>/km/download --privacy-url https://<portal>/km/privacy \
    --project lifelinkkh
```

Writes `config/app`, which the app reads once at start: older than `latestVersionCode` → "a new
version is available"; older than `minVersionCode` (only moved with `--min`) → "update required".
Run it after the APK is on GitHub Releases. The whole path: `docs/tech-lead/deploy-runbook.md`
Path A, and `bash scripts/build-release-apk.sh` from the repo root.

## Demo data and metrics

```bash
npm run seed:demo      # emulator only: two O- donors, a requester, one CRITICAL request at Calmette,
                       # matched by the portal's real handleRequestApproved and accepted by one
                       # donor through its respondToMatch. Clears requests, matches and donations first.
npm run metrics        # the five PRD success metrics from the emulator's data
npm run metrics -- --project lifelinkkh   # …from the real project (GOOGLE_APPLICATION_CREDENTIALS)
```

`seed:demo` imports the handlers from `frontend/src/server/` (so `frontend/` needs its
`npm install`): the matching is the real code, not a copy. FCM has no emulator, so the pushes go
to `_outbox`; the match documents and counts are still written.

## The portal on Firebase (phase 5)

The Next.js portal is **admin-only** in v1 (DEC-014): no hospital staff, no staff page. It reads
Firestore over REST from its own server, with the admin's ID token from the httpOnly session
cookie, so the rules judge it as they judge the app; `reviewRequest` and `confirmDonation` run
in-process on that server (ADR 0010). The admin signs in with Firebase Auth email + password or
Google (DEC-017); the username is the email's local part (`portalEmail()` in
`frontend/src/server/portal-accounts.js` and `frontend/src/lib/api/portal-auth.ts`).

```bash
cd firebase
npm run emulators:app                     # Firestore + Auth, project lifelinkkh
npm run seed:app                          # second terminal
PORTAL_ADMIN_PASSWORD=… npm run seed:admin:app   # soborey

cd ../frontend
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run dev
```

The password is at least 12 characters; unset, no admin is created. A re-run keeps the password
unless `--reset-passwords` is passed. To end an admin's access, delete `admins/{uid}` (the rules
refuse them on the next read) and disable the user in the console. Against the real project the portal needs
`FIREBASE_API_KEY` (a Web API key for `lifelinkkh`, from the console — not a secret),
`FIREBASE_SERVICE_ACCOUNT` (the service-account JSON, for the functions) and no emulator variables.

Deploying the rules and indexes (the project stays on the free Spark plan — ADR 0010):

```bash
npx firebase deploy --only firestore --project lifelinkkh
```
