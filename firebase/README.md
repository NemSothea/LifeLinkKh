# firebase/

The Firebase backend that replaces Spring Boot + PostgreSQL — ADR 0009, branch `feat/firebase-backend`.

| File | What |
|---|---|
| `firestore.rules` | Who reads and writes what. The only thing between a client and the data |
| `rules-tests/` | One emulator test per rule. A rule without a test is treated as absent |
| `firestore.indexes.json` | Composite indexes for the board, "my requests", "my matches", history |
| `firebase.json` | Emulator ports: auth 9099, firestore 8081, functions 5001, UI 4000 |
| `functions/` | Cloud Functions. `onRequestCreated`: rate limit and hospital name while `PENDING`. `onRequestApproved`: matching, match documents, donor alert, requester told. `onMatchAnswered`: accepted count, public board row, "donor accepted" push. Callables for the portal admin: `reviewRequest` (approve/reject, DEC-015), `confirmDonation`. For the app: `deleteAccount` (DEC-016) |
| `seed/` | Districts and hospitals (V3, V7), same ids as Postgres. `reference-data.json` is the source. `admin.mjs`: the portal's admin account (V13's `soborey`) |

The data model and the reason behind each rule: `docs/tech-lead/firestore-data-model.md`.

```bash
cd firebase
npm install
npm run test:rules     # starts the Firestore emulator, runs vitest, stops it (needs Java 21)
npm run emulators      # emulators + UI at http://localhost:4000, for poking by hand
npm run test:seed      # seeds an emulator and checks 14 districts, 5 hospitals, no orphans

cd functions && npm install
npm test               # matching and push, pure — every clause of the old matching SQL
npm run test:emulator  # every handler against the Firestore emulator, FCM faked
```

On a `demo-` project the Functions write every push to `_outbox` instead of sending it: FCM has
no emulator, and this is how a test reads exactly what a donor would have received.

## Running the app against the emulator

The app is built for the `lifelinkkh` project, so the emulator it talks to must run under that
id — not `demo-lifelink`, which is the tests' own sandbox.

```bash
cd firebase
npm run emulators:app                     # Firestore 8081, Auth 9099, Functions 5001 — project lifelinkkh
npm run seed:app                          # second terminal: districts + hospitals into it

cd ../mobile
flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081      # Android emulator
# USB phone: adb reverse tcp:8081 tcp:8081, then FIRESTORE_EMULATOR=127.0.0.1:8081
```

Leave `FIRESTORE_EMULATOR` unset to use the real project. That needs Firestore created in the
console, `npx firebase deploy --only firestore --project lifelinkkh` for the rules and indexes,
and `npm run seed -- --project lifelinkkh` once.

## Nothing touches a backend (phase 6)

There is no Spring Boot and no Postgres any more. The app and the portal talk to Firebase only:
sign-in (the Firebase ID token is the session; `users/{uid}` is the record), donor profile,
requests, matching and the donor alert, the donor's matches, accept/decline, the "donor
accepted" push, and the portal's confirm-donation. Telegram sign-in was dropped (it needed a
custom-token Function), and the app no longer takes `API_BASE_URL`.

## Deleting an account (DEC-016)

The app's **Me → Delete account** calls `deleteAccount` with a fresh sign-in. For someone who
wrote in through the portal's `/{locale}/delete-account` page instead:

```bash
npm run delete-account -- --uid <uid>                        # emulator
npm run delete-account -- --uid <uid> --project lifelinkkh   # REAL — GOOGLE_APPLICATION_CREDENTIALS
```

Irreversible. Personal data is deleted; requests, matches and donations are kept with the uid
cleared, so the metrics stay honest. It refuses an admin account.

## Demo data and metrics

```bash
npm run seed:demo      # emulator only: two O- donors, a requester, one CRITICAL request at Calmette,
                       # matched by the real onRequestCreated and accepted by one donor.
                       # Clears requests, matches and donations first.
npm run metrics        # the five PRD success metrics from the emulator's data
npm run metrics -- --project lifelinkkh   # …from the real project (GOOGLE_APPLICATION_CREDENTIALS)
```

`seed:demo` needs the Functions emulator running (`npm run emulators:app`): the matching is the
real Function, not a copy. FCM has no emulator, so on `lifelinkkh` the Functions emulator's push
attempt fails and is logged; the match documents and counts are still written.

## The portal on Firebase (phase 5)

The Next.js portal is **admin-only** in v1 (DEC-014): no hospital staff, no staff page. It reads
Firestore and calls `confirmDonation` over REST from its own server, with the admin's ID token from
the httpOnly session cookie, so the rules judge it as they judge the app. The admin signs in with
Firebase Auth email + password; the username is the email's local part (`portalEmail()` in
`functions/src/portal-accounts.js` and `frontend/src/lib/api/portal-auth.ts`).

```bash
cd firebase
npm run emulators:app                     # Firestore + Auth + Functions, project lifelinkkh
npm run seed:app                          # second terminal
PORTAL_ADMIN_PASSWORD=… npm run seed:admin:app   # soborey

cd ../frontend
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001 npm run dev
```

The password is at least 12 characters; unset, no admin is created. A re-run keeps the password
unless `--reset-passwords` is passed. To end an admin's access, delete `admins/{uid}` (the rules
refuse them on the next read) and disable the user in the console. Against the real project the portal needs
`FIREBASE_API_KEY` (a Web API key for `lifelinkkh`, from the console — not a secret) and no
emulator variables.

Deploying the Functions needs the Blaze plan on `lifelinkkh`:

```bash
npx firebase deploy --only firestore,functions --project lifelinkkh
```
