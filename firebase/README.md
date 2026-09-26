# firebase/

The Firebase backend that replaces Spring Boot + PostgreSQL — ADR 0009, branch `feat/firebase-backend`.

| File | What |
|---|---|
| `firestore.rules` | Who reads and writes what. The only thing between a client and the data |
| `rules-tests/` | One emulator test per rule. A rule without a test is treated as absent |
| `firestore.indexes.json` | Composite indexes for the board, "my requests", "my matches", history |
| `firebase.json` | Emulator ports: auth 9099, firestore 8081, functions 5001, UI 4000 |
| `functions/` | Cloud Functions. `onRequestCreated`: rate limit, matching, match documents, push |
| `seed/` | Districts and hospitals (V3, V7), same ids as Postgres. `reference-data.json` is the source |

The data model and the reason behind each rule: `docs/tech-lead/firestore-data-model.md`.

```bash
cd firebase
npm install
npm run test:rules     # starts the Firestore emulator, runs vitest, stops it (needs Java 21)
npm run emulators      # emulators + UI at http://localhost:4000, for poking by hand
npm run test:seed      # seeds an emulator and checks 14 districts, 5 hospitals, no orphans

cd functions && npm install
npm test               # matching and push, pure — every clause of the old matching SQL
npm run test:emulator  # the whole handler against the Firestore emulator, FCM faked
```

On a `demo-` project the Functions write every push to `_outbox` instead of sending it: FCM has
no emulator, and this is how a test reads exactly what a donor would have received.

## Running the app against the emulator

The app is built for the `lifelinkkh` project, so the emulator it talks to must run under that
id — not `demo-lifelink`, which is the tests' own sandbox.

```bash
cd firebase
npm run emulators:app                     # Firestore emulator as project lifelinkkh, port 8081
npm run seed:app                          # second terminal: districts + hospitals into it

cd ../mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api \
            --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081      # Android emulator
# USB phone: adb reverse tcp:8081 tcp:8081, then FIRESTORE_EMULATOR=127.0.0.1:8081
```

Leave `FIRESTORE_EMULATOR` unset to use the real project. That needs Firestore created in the
console, `npx firebase deploy --only firestore --project lifelinkkh` for the rules and indexes,
and `npm run seed -- --project lifelinkkh` once.

## Phase 3 is still a mixed state

On Firestore now: donor profile, districts, donation history, requests (post, board, mine,
detail, cancel), the push token, and matching + the donor alert in `onRequestCreated`.

Still on the Spring Boot backend until phase 4: **sign-in** (the session JWT), **matches**
(the donor's list, accept/decline) and the "donor accepted" push. So `API_BASE_URL` and
`dev-up.sh` are still needed. On this branch a donor now gets the alert, and tapping it
opens a match screen that reads the backend — which has no such match. Phase 4 closes that.

Deploying the Function needs the Blaze plan on `lifelinkkh`:

```bash
npx firebase deploy --only firestore,functions --project lifelinkkh
```
