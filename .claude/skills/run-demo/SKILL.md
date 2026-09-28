---
name: run-demo
description: Stand up the LifeLink KH demo on this machine — Firebase emulators (Firestore + Auth), fresh seed and demo data, the admin portal in a browser (it also serves the app's functions, ADR 0010), and the Flutter app on emulator / USB phone / iOS simulator pointed at the local emulator and portal. Use when the user says "run the demo", "start the emulators", "open the portal", "run mobile", "prep for defense", or "reset demo data".
argument-hint: "[all | stack | reset | portal | mobile [emulator|usb|ios] | check | stop]"
---

# Run the LifeLink demo

Source of truth is `docs/demo-runbook.md` (and `firebase/README.md` for the Firebase side). This
skill runs it; it does not replace it. When they disagree, the runbook wins — fix this file.

Parse `$ARGUMENTS`. No argument means `all`. Do only the steps the argument names.

| Argument | Steps |
|---|---|
| `all` | 1 → 2 → 3 → 4 → 5 |
| `stack` | 1 |
| `reset` | 2 |
| `portal` | 3 |
| `mobile [target]` | 4 (target default `emulator`) |
| `check` | 5 |
| `stop` | Stop the background emulator and `npm run dev` processes. Say that the emulators keep nothing — the next start needs step 2 again |

This skill runs the **emulator stack**, which delivers **no pushes** (FCM has no emulator; runbook
§0). If the user wants the alert to arrive on a phone, that is the real project (runbook §2) —
say so and stop rather than improvising a deploy.

## 1. Stack — Firebase emulators

```bash
cd firebase && npm run emulators:app     # Firestore :8081 · Auth :9099 · UI :4000
```

- Run with `run_in_background: true`; it stays attached. Wait for `All emulators ready`
  (poll `curl -fsS http://127.0.0.1:8081/` and `http://127.0.0.1:4000/`).
- Needs **Java 21**. A version error → report it; do not install a JDK.
- `node_modules` missing in `firebase/` or `frontend/` → `npm install` in each first (the demo seed
  runs the portal's handlers, which live in `frontend/src/server`).
- Always `emulators:app` (project `lifelinkkh`), never `npm run emulators` — that is
  the tests' `demo-lifelink` sandbox, which the app cannot see.

## 2. Data — seed

The emulators start empty. After every start:

```bash
cd firebase
npm run seed:app                                           # districts + hospitals
PORTAL_ADMIN_PASSWORD="$PORTAL_ADMIN_PASSWORD" npm run seed:admin:app   # soborey
npm run seed:demo                                          # 2 O− donors, requester, CRITICAL AB+ at Calmette (approved, 1 acceptance), URGENT O+ pending review
```

- `PORTAL_ADMIN_PASSWORD` comes from the user's `.env` (`set -a; . ./.env; set +a` from the repo
  root). Unset → the seed creates no admin; tell the user. Under 12 characters → `REFUSED`.
- `seed:demo` deletes requests, matches and donations first. It is emulator-only, so no
  confirmation is needed on the emulator stack; it must print `… 1 accepted — ready to confirm in
  the portal` and `demo-pending: waiting in the portal's review queue`. `matching found nobody`
  → the seed data is not intact; re-run `seed:app` first.
- Why every rehearsal: a confirmed donation puts that donor into a 56-day cooldown, and the next
  run matches nobody (runbook §4, trap 2).

## 3. Web portal

```bash
cd frontend
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run dev
```

- Background it. Both variables or none. **The portal must be up before the app** (step 4): the
  app posts requests, answers alerts and deletes accounts through `http://<host>:3000/api/functions/…`
  (ADR 0010) — `demo-mobile.sh` passes `PORTAL_URL` for it.
- `open http://localhost:3000/en/portal` — the public board, signed out; show this first.
- `open http://localhost:3000/en/sign-in` — the only account is `soborey` (ADMIN, DEC-014).
  No hospital-staff accounts exist.
- **Never print the password in the chat.** It is the user's `PORTAL_ADMIN_PASSWORD`.
- Khmer: swap `/en/` for `/km/`.

## 4. Mobile

```bash
bash scripts/demo-mobile.sh emulator --firestore-emulator   # donor — Android AVD, boots it, cycles airplane mode
bash scripts/demo-mobile.sh usb --firestore-emulator        # physical Android on a cable (adb reverse tcp:8081)
bash scripts/demo-mobile.sh ios --firestore-emulator        # simulator — no push, never the donor
```

Run it with `run_in_background: true` — `flutter run` stays attached. Tell the user it is
building (first build is minutes) and that `r` / `q` work if they run it in their own terminal.
Sign-in is real Google Sign-In even on the emulator stack, so the device needs internet.

Rules the golden path depends on:
- **Two Google accounts, one role each.** A donor never matches their own request.
- **Donor on Android** (emulator with Play image, or USB phone). iOS Simulator has no APNs.
- Pinned values: donor district **Doun Penh**, last donation **blank**; request at **Calmette**,
  patient **AB+**, urgency **CRITICAL** (runbook §4 table). Do not improvise the patient type.

## 5. Pre-flight check

```bash
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:4000/          # Emulator UI 200
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/en/portal    # 200
```

Then, in the Emulator UI (http://localhost:4000 → Firestore), after the donor registers on the
phone and before the request is posted (runbook §4 "Prove the match"):
`donors/{uid}` compatible type, `isAvailable: true`, `lastDonationDate` null or 56+ days ago;
`users/{uid}.fcmToken` not null. After posting, `matches/{requestId}_{uid}` must exist. The
`seed:demo` donors always have a null token — expected, not a fault.

## Report

End with one block, nothing more:

```
emulators ✅ | ❌  (firestore, auth)
data      ✅ seeded (+admin, +demo) | ⏭ skipped
portal    ✅ 200 | ❌
mobile    ✅ running on <device> | ⏳ building | ⏭
preflight match ready | no token | no match — <reason>
pushes    none on the emulator stack
```

Quote only the shortest decisive failing line. Never paste full logs. Do not fix code during a
demo run — report and stop.
