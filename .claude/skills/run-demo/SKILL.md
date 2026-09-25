---
name: run-demo
description: Stand up the LifeLink KH demo on this machine — Docker stack (postgres + backend + web portal), fresh demo data, the portal in a browser, and the Flutter app on emulator / USB phone / iOS simulator. Use when the user says "run the demo", "start docker", "open the portal", "run mobile", "prep for defense", or "reset demo data".
argument-hint: "[all | stack | reset | portal | mobile [emulator|usb|ios] | check | stop]"
---

# Run the LifeLink demo

Source of truth is `docs/demo-runbook.md`. This skill runs it; it does not replace it. When the
two disagree, the runbook wins — fix this file.

Parse `$ARGUMENTS`. No argument means `all`. Do only the steps the argument names.

| Argument | Steps |
|---|---|
| `all` | 1 → 2 → 3 → 4 → 5 |
| `stack` | 1 |
| `reset` | 2 |
| `portal` | 3 |
| `mobile [target]` | 4 (target default `emulator`) |
| `check` | 5 |
| `stop` | `docker compose stop` — never `down -v` (that deletes the database volume) |

## 1. Stack — Docker

```bash
bash scripts/dev-up.sh          # add --lan only for the wireless hotspot demo (runbook §10)
```

- Always `dev-up.sh`, never a bare `docker compose up --build backend`: the bare command drops the
  Firebase overlay and every phone sign-in then answers `503 AUTH_PROVIDER_UNCONFIGURED` (runbook §6).
- Docker Desktop not running → tell the user to open it; do not try to start it.
- Then verify the Firebase key really mounted:
  ```bash
  curl -s -X POST http://127.0.0.1:8080/api/auth/google -H 'Content-Type: application/json' -d '{"idToken":"nonsense"}'
  ```
  `INVALID_ID_TOKEN` = good. `AUTH_PROVIDER_UNCONFIGURED` = key missing, stop and report.

## 2. Demo data — reset + seed

**Irreversible** on the local database: requests, matches, donations and donor accounts go;
districts, hospitals and staff accounts stay. Confirm with the user before running it unless
they asked for `reset` or `all` explicitly in this turn.

```bash
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/reset-demo-data.sql
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/seed-demo-request.sql
```

Why every time: a rehearsal that reached "confirm donation" leaves that donor in a 56-day
cooldown, and the next run matches nobody (runbook §3, trap 2).

## 3. Web portal

```bash
open http://localhost:3000/en/portal     # public board, signed out — show this first
bash scripts/demo-creds.sh staff         # copies calmette's password to the clipboard
open http://localhost:3000/en/sign-in
```

- Demo as `calmette` (the golden-path request is at Calmette). `soborey` = ADMIN.
- **Never print a password in the chat.** Use `demo-creds.sh staff|admin` (clipboard) only.
- Khmer: swap `/en/` for `/km/`.

## 4. Mobile

```bash
bash scripts/demo-mobile.sh emulator     # donor — Android AVD, boots it and refreshes FCM
bash scripts/demo-mobile.sh usb          # physical Android on a cable (adb reverse)
bash scripts/demo-mobile.sh ios          # simulator — no push, never the donor
```

Run it with `run_in_background: true` — `flutter run` stays attached. Tell the user it is
building (first build is minutes) and that `r` / `q` work if they run it in their own terminal.

Rules the golden path depends on:
- **Two Google accounts, one role each.** A donor never matches their own request.
- **Donor on Android** (emulator with Play image, or USB phone). iOS Simulator has no APNs.
- Requester needs a push-capable device too if the "donor accepted" alert is shown (FR-NOTIFY-003).
- Pinned values: donor district **Doun Penh**, last donation **blank**; request at **Calmette**,
  patient **AB+**, urgency **CRITICAL** (runbook §3 table). Do not improvise the patient type.

## 5. Pre-flight check

```bash
curl -s http://127.0.0.1:8080/api/health                        # {"status":"UP"}
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/en/portal   # 200
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/preflight-match.sql
```

Run the pre-flight **after the donor registers on the phone, before the request is posted**.
`MATCH — the alert fires` = ready. Seeded donors always read `matched, but SILENT` (no device) —
expected, not a fault. No MATCH row for the real donor → name the reason from the row.

## Report

End with one block, nothing more:

```
stack    ✅ | ❌  (health, firebase key)
data     ✅ reset+seeded | ⏭ skipped
portal   ✅ 200 | ❌
mobile   ✅ running on <device> | ⏳ building | ⏭
preflight MATCH | SILENT | no row — <reason>
```

Quote only the shortest decisive failing line. Never paste full logs. Do not fix code during a
demo run — report and stop.
