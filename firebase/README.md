# firebase/

The Firebase backend that replaces Spring Boot + PostgreSQL — ADR 0009, branch `feat/firebase-backend`.

| File | What |
|---|---|
| `firestore.rules` | Who reads and writes what. The only thing between a client and the data |
| `rules-tests/` | One emulator test per rule. A rule without a test is treated as absent |
| `firestore.indexes.json` | Composite indexes for the board, "my requests", "my matches", history |
| `firebase.json` | Emulator ports: auth 9099, firestore 8081, functions 5001, UI 4000 |
| `functions/` | Cloud Functions. `onRequestCreated`: rate limit, matching, match documents, donor alert. `onMatchAnswered`: accepted count, public board row, "donor accepted" push |
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

## After phase 4: what still touches the backend

The whole golden path is on Firebase now: sign-in (the Firebase ID token is the session;
`users/{uid}` is the record), donor profile, requests, matching and the donor alert, the
donor's matches, accept/decline, and the "donor accepted" push.

Still on Spring Boot until phase 6:

- **Telegram sign-in.** It needs a custom-token Function; until then a Telegram user has
  no Firebase identity and every Firestore call refuses them.
- **`API_BASE_URL` is still required**, because the Telegram repository builds its Dio
  client at startup. Nothing on the golden path calls the backend.
- **The portal** (phase 5) still reads Postgres, so it does not see requests made here.

Known gap, for phase 6: a stored session is restored even when Firebase has no signed-in
user. It cannot happen on a normal install — both are cleared together — but a restored
session with no Firebase user would show Home and fail every read until sign-out.

Deploying the Functions needs the Blaze plan on `lifelinkkh`:

```bash
npx firebase deploy --only firestore,functions --project lifelinkkh
```
