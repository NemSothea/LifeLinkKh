# firebase/

The Firebase backend that replaces Spring Boot + PostgreSQL — ADR 0009, branch `feat/firebase-backend`.

| File | What |
|---|---|
| `firestore.rules` | Who reads and writes what. The only thing between a client and the data |
| `rules-tests/` | One emulator test per rule. A rule without a test is treated as absent |
| `firestore.indexes.json` | Composite indexes for the board, "my requests", "my matches", history |
| `firebase.json` | Emulator ports: auth 9099, firestore 8081, functions 5001, UI 4000 |
| `seed/` | Districts and hospitals (V3, V7), same ids as Postgres. `reference-data.json` is the source |

The data model and the reason behind each rule: `docs/tech-lead/firestore-data-model.md`.

```bash
cd firebase
npm install
npm run test:rules     # starts the Firestore emulator, runs vitest, stops it (needs Java 21)
npm run emulators      # emulators + UI at http://localhost:4000, for poking by hand
npm run test:seed      # seeds an emulator and checks 14 districts, 5 hospitals, no orphans
```

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

## Phase 2 is a mixed state

Donor profile, districts and donation history are on Firestore. Sign-in, requests, matches and
push are still on the Spring Boot backend until phases 3–4, so `API_BASE_URL` is still required
and `dev-up.sh` still has to be running. Matching on the backend reads Postgres donors, which
this branch no longer writes — **on this branch the golden path does not match anyone until
phase 3**. `main` is the demo.

Both use the project id `demo-lifelink`: the `demo-` prefix keeps the emulator from ever touching
the real `lifelinkkh` project.
