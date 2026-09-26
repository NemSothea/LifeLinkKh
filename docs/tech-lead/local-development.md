# Local development — running the stack

**Owner: Tech Lead.** This is the first half of the deploy runbook. It covers getting the
Firebase emulators, the portal and the app running on a developer machine, and nothing about
deploying anywhere real — for the signed-AAB / Play Store internal testing half, see
[`deploy-runbook.md`](deploy-runbook.md).

> **Rewritten 2026-09-26 for [ADR 0009](adr/0009-firebase-replaces-spring-boot-and-postgres.md).**
> The Spring Boot backend, PostgreSQL and Docker are gone. The "stack" is now the Firebase
> Emulator Suite (Firestore, Auth, Functions) standing in for the `lifelinkkh` project, plus the
> Next.js portal and the Flutter app pointed at it. [`firebase/README.md`](../../firebase/README.md)
> is the source of truth for the Firebase side; this page is the machine setup around it.

---

## Prerequisites

| Tool | Version | Why this version |
|---|---|---|
| JDK | **21** | The Firebase emulators are a Java program and refuse older runtimes. `scripts/verify-all.sh` pins `JAVA_HOME` to a 21 install when it can find one |
| Node | **22** | Node 20 trips `EBADENGINE` on deps requiring `>=22`. CI pins 22 |
| Flutter SDK | 3.44.6 | Mobile only. Pinned exactly in CI — never bare `stable` |
| Android SDK + a Google Play AVD | API 36 | A plain AOSP image has no Play services and therefore no FCM |

`firebase-tools` comes in as a dev dependency of `firebase/` — use `npx firebase …`, no global
install needed.

---

## Step 1 — install

```bash
cd firebase && npm install
cd functions && npm install
cd ../../frontend && npm install
cd ../mobile && flutter pub get
```

## Step 2 — `.env`

```bash
cp .env.example .env
```

**`.env` is gitignored and MUST NEVER be committed.** For the emulator stack almost nothing in it
is needed: the scripts in `firebase/` default to the emulator, and the only value you supply is
`PORTAL_ADMIN_PASSWORD` (12+ characters) for the portal admin. `.env.example` documents every
variable, including `GOOGLE_APPLICATION_CREDENTIALS` for running the seed and metrics scripts
against the **real** project.

Next.js reads env files from `frontend/`, not the repo root, so the portal's emulator variables
(Step 4) go inline or in `frontend/.env.local` (also gitignored).

## Step 3 — emulators and seed data

Terminal 1, left running:

```bash
cd firebase
npm run emulators:app     # Firestore :8081 · Auth :9099 · Functions :5001 · UI :4000, project lifelinkkh
```

Terminal 2:

```bash
cd firebase
npm run seed:app                                           # districts + hospitals
PORTAL_ADMIN_PASSWORD='<12+ chars>' npm run seed:admin:app # the portal admin, soborey
npm run seed:demo                                          # optional: demo donors + one matched request
```

The emulators keep **nothing** across a stop — re-run the seeds after every start.

Why the project id is `lifelinkkh` and not `demo-lifelink`: the app is built for `lifelinkkh`
(its `google-services.json` names it), so the emulator it talks to must run under that id.
`demo-lifelink` is the tests' own sandbox (`npm run emulators`, `npm run test:rules`), where the
Functions write every push to `_outbox` instead of sending it. Under `lifelinkkh` they try real
FCM and fail without credentials — so the emulator stack delivers no pushes.

## Step 4 — the portal

```bash
cd frontend
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001 \
npm run dev
```

http://localhost:3000 — Khmer by default. Set all three emulator variables or none; one left
set points the portal at an emulator and the rest at the real project. Against the real project,
drop them and set `FIREBASE_PROJECT_ID=lifelinkkh` and `FIREBASE_API_KEY` (the project's Web API
key, not a secret).

The portal talks to Firebase over REST **from the Next server**, with the admin's ID token in an
httpOnly cookie, so the Security Rules judge it exactly as they judge the app. There is no
service account on the web server.

## Step 5 — the Flutter app

```bash
bash scripts/demo-mobile.sh --firestore-emulator            # Android emulator (boots the AVD)
bash scripts/demo-mobile.sh usb --firestore-emulator        # cabled phone, adds adb reverse tcp:8081
bash scripts/demo-mobile.sh ios --firestore-emulator        # booted simulator — no push
```

By hand: `cd mobile && flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081` on the
Android emulator (`10.0.2.2` is its alias for this Mac); a USB phone needs
`adb reverse tcp:8081 tcp:8081` then `127.0.0.1:8081`; the iOS simulator uses `127.0.0.1:8081`.
Leave `FIRESTORE_EMULATOR` unset (plain `flutter run`) for the real project. A wrong address
looks exactly like an empty database, which is why the script exists.

Only Firestore is redirected — sign-in is always real Google Sign-In through Firebase Auth, so
the one-time Firebase setup below applies even to local work.

## Step 6 — checks

```bash
bash scripts/verify-all.sh
```

Firestore rules tests, Functions unit and emulator tests, web lint/types/tests, `flutter
analyze` and `flutter test` — the same steps as the `firebase`, `web` and `mobile` jobs in CI.
A skipped test is not a pass; read the report.

---

## One-time Firebase setup (already done for `lifelinkkh`)

Recorded because a new project, or a new developer machine, repeats parts of it.

1. **Android app** — package name **`kh.lifelink.app`**, `google-services.json` in
   `mobile/android/app/`. That file **is committed on purpose**: it is client configuration, its
   API key is restricted by package name and fingerprint, and the CI release build needs it.
2. **Debug SHA-1 per machine** — `cd mobile/android && ./gradlew signingReport`, take the SHA1 of
   the `debug` variant, add it in the console. **Google Sign-In fails silently without it** — no
   exception, no dialog, the sheet simply returns nothing. A new laptop has a new debug keystore
   and needs its own entry. A release SHA-1 from the upload keystore is needed before M7.
3. **Authentication** → enable Google (the app) and Email/Password (the portal admin).
4. **Firestore** created in **`asia-southeast1`**; rules, indexes and Functions deployed with
   `npx firebase deploy --only firestore,functions --project lifelinkkh`. Functions need the
   **Blaze** plan — set a budget alert when you enable it.
5. **Service-account key**, only for running seed/metrics scripts against the real project.
   Project settings → Service accounts → Generate new private key → `secrets/` (gitignored
   wholesale, and `*firebase-adminsdk*.json` / `*service-account*.json` are ignored anywhere).
   **If a key ever reaches a commit, it is compromised** — revoke it in the console; deleting the
   file in a later commit does nothing, the object stays in every clone. Confirm rather than trust:
   `git status --porcelain -uall secrets/` must list only `secrets/README.md`.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Emulators refuse to start / Java version error | JDK older than 21 on the `PATH` | Install 21 and set `JAVA_HOME` |
| `seed:demo` prints `onRequestCreated never ran` | Emulators started without Functions | `npm run emulators:app`, not `npm run emulators` |
| Portal: "Could not load the request list" | Emulators down, or only some emulator variables set | Step 4 |
| Portal sign-in refused after an emulator restart | Auth emulator forgot the admin | Re-run `seed:admin:app` |
| App shows nothing on the emulator stack | Wrong `FIRESTORE_EMULATOR` for the device | Use `scripts/demo-mobile.sh` |
| Google Sign-In returns nothing at all, no error | This machine's debug SHA-1 is not registered | One-time setup, item 2 |
| A match is written, no push arrives | Emulator stack (no FCM), a null `fcmToken`, or a dead FCM socket on a snapshot AVD | `docs/demo-runbook.md` §7 |
| `seed … --project lifelinkkh` refuses to run | An emulator host variable is set in the shell | Unset it — otherwise "lifelinkkh" would silently mean the emulator |
| Every portal route 500s after a build | `npm run build` while `next dev` was running; they share `.next` | Stop dev, `rm -rf .next`, restart |

---

## Related

- [`firebase/README.md`](../../firebase/README.md) — the Firebase side: rules, Functions, seeds, emulators
- [`firestore-data-model.md`](firestore-data-model.md) — collections and the reason behind each rule
- [`deploy-runbook.md`](deploy-runbook.md) — second half: signed AAB, Play Store internal testing (M7)
- [`../demo-runbook.md`](../demo-runbook.md) — standing up a demo on top of this
- [`../qa/test-strategy.md`](../qa/test-strategy.md) — what QA needs before signing a milestone
- [`../security/security-checklist.md`](../security/security-checklist.md) — secret handling
- `scripts/demo-mobile.sh`, `scripts/verify-all.sh` — owned by Tech Lead
