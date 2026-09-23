# Demo runbook

**Owner:** Tech Lead. Read this before any defense, sprint review, or ad-hoc "show me the app."
It is the golden path plus the known gaps — say the gaps out loud rather than hoping nobody
notices them live.

## 1. Bring up the stack

```bash
cp .env.example .env   # first time only — fill in real values, NEVER commit .env
bash scripts/dev-up.sh
```

This starts Postgres (`:5433`), backend (`:8080`), web portal (`:3000`), all bound to
`127.0.0.1`. Confirm before doing anything else:

```bash
curl -s http://127.0.0.1:8080/api/health   # {"status":"UP"}
```

## 2. Run the mobile app

See `mobile/README.md` "Run it" for the two one-time setup steps
(`google-services.json`, debug SHA-1 registered in Firebase) — both are already done on
this machine as of 2026-08-22. Then:

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

Use **two accounts** (two emulators, or one emulator + one physical device) — a donor and a
requester. `RequestController` deliberately lets any signed-in user post a request (a donor
whose relative needs blood is the likely case), but using one account for both roles makes
the demo confusing to watch, not clearer.

## 3. The golden path (what to actually show)

**The values below are pinned, not examples.** Matching is a filter chain, and a request that
passes none of it is not an error anywhere in the product: the API answers 201, the portal lists
the request, and the donor's phone stays silent. `FR-MATCH-002` (retry with a wider radius) is
deferred, so nothing widens and nothing on screen explains the silence. Improvising a blood type
in front of an audience is how that happens.

| Step | Field | Pinned value | Why this one |
|---|---|---|---|
| 1 | **Account A** — blood type | **O−**, or the donor's real type | O− is the universal donor, so nothing can miss it. But the pin that actually protects this demo is the patient's type below — with an AB+ patient, **any** donor type matches, so use whatever the account already has if it is registered |
| 1 | Account A — district | **Doun Penh (1202)** | Calmette's own district. If the donor grants GPS, the distance is ~0 km, far inside the 10 km radius |
| 1 | Account A — last donation | **leave blank** | NULL means never donated, which means immediately eligible. Any date inside 56 days removes the donor from every match |
| 2 | **Account B** — hospital | **Calmette Hospital** | Seeded by `V7__seed_hospitals.sql`, and the district above is chosen against it |
| 2 | Account B — patient type | **AB+** | **The one value not to improvise.** AB+ is the universal recipient — it accepts all eight donor types, so the match survives whatever the donor registered. Change this field and compatibility becomes a real filter again: an A+ donor, for instance, can give only to A+ and AB+ |
| 2 | Account B — urgency | **CRITICAL** | Top tier reads clearest on the portal list, and urgency does not affect matching |

1. **Account A** — Google Sign-In, register as donor with the values above.
2. **Account B** — Google Sign-In, create an urgent request with the values above.
3. Matching + push fires. Account A gets a push notification within seconds (FCM). Open it.
4. Account A **accepts**.
5. Switch to the **web portal** (`http://localhost:3000/km` — Khmer by default, English via
   the language switcher top-right). Sign in as staff (section 4), open the request row —
   Account A is listed as an accepted donor. Click **confirm donation**.
6. Back on Account A's app — donation history now shows the entry, eligibility flips to
   "next eligible in 56 days."

That loop — register, request, match, push, accept, confirm, history — is the whole product.
Everything else in `docs/scope.md`'s "8 FRs built" table supports one of these six steps.

### Prove the match before the room does

```bash
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/preflight-match.sql
```

One row per donor, with the verdict spelled out: `MATCH — the alert fires`, or the specific
reason it will not. Run it after Account A registers and before Account B posts the request. If
no row says MATCH, the demo is about to show an empty screen and there is still time to fix it.

The seeded donors always read `matched, but SILENT` — they are database rows, not installs, so
they have no FCM token and never will. Only a donor registered from a real device shows
`MATCH — the alert fires`. Seeing SILENT for Sok Dara and Ly Ratanak is the expected state, not
a fault.

Who can give to whom, if the question comes up mid-demo (`blood_compatibility`, ADR 0004 —
whole blood and red cells only):

| Patient | Accepts blood from |
|---|---|
| AB+ | everyone — A+, A−, AB+, AB−, B+, B−, O+, O− |
| AB− | A−, AB−, B−, O− |
| A+ | A+, A−, O+, O− |
| A− | A−, O− |
| B+ | B+, B−, O+, O− |
| B− | B−, O− |
| O+ | O+, O− |
| O− | O− only |

### The five ways this goes silent

Each one is a real filter in `DonorCandidateRepository.findCandidates`, and none of them
produces an error the audience can see.

1. **One account playing both roles.** `dp.user_id <> :requesterUserId` — a donor never matches
   their own request. Deliberate (nobody should be alerted to donate to themselves), and the
   fastest way to a silent demo. Two accounts, always.
2. **Step 6 already ran today.** Confirming a donation starts the 56-day cooldown, and that donor
   is then excluded from every match. **Rehearsing the full loop twice with the same donor gives
   a silent second run.** Use a different donor account for the rehearsal, or clear the donation
   row before the real thing.
3. **Donor marked unavailable.** `is_available` is a toggle in the app, and a rehearsal may have
   left it off.
4. **GPS granted from a district too far out.** A donor with no coordinates matches regardless
   and simply ranks last; a donor **with** coordinates is cut at 10 km (`MATCHING_RADIUS_KM`).
   Granting location from outside Phnom Penh's centre is therefore *worse* than declining it. The
   pinned district avoids the question.
5. **No FCM token on that install.** The match row is still written and the portal still shows
   the request — only the push is missing, which looks identical to "matching is broken" from the
   audience's side. Tokens are per-install: a reflashed or reinstalled device has a new one, and
   `scripts/preflight-match.sql` reports this case separately as `matched, but SILENT`.

Sixth, not a matching rule but the same silent shape: `REQUEST_RATE_LIMIT_MAX_ATTEMPTS` is 5
requests per 10 minutes per user. A long rehearsal that posts request after request from Account
B will hit it and the next create answers 429.

### Measured, 2026-09-23

A cold rehearsal on this machine — `docker compose down`, then the commands above, images
already built:

| From `docker compose down` to | Elapsed |
|---|---|
| `/api/health` answering `{"status":"UP"}` | **40 s** |
| portal answering 200 on `/km/portal` | **43 s** |
| reset + seed applied | **49 s** |
| pre-flight and board verified | **55 s** |

So the stack is demo-ready inside a minute, and the six-minute budget in
[`po/demo-script.md`](po/demo-script.md) §8 is nearly all narration. First build is another
matter — if the images are not on the machine, `dev-up.sh` compiles the backend and builds Next,
which is minutes. Build them the day before, not in the room.

The same rehearsal drove the whole loop through the API rather than the UI (mint a DONOR token
with `scripts/mint-portal-jwt.py`, POST `/requests`, POST `/matches/{id}/respond`, POST
`/portal/requests/{id}/confirm-donation`): request created with `alertedCount: 2`, accept
revealed the requester's contact, confirm answered 201 with
`"donorNextEligibleOn": "2026-11-18"`, and `/donations/me` showed the entry. That is the golden
path minus the two things curl cannot check — the push arriving on a phone, and the screens.

It also demonstrated trap 2 above in the most direct way available: the rehearsal's own confirm
put Sok Dara into cooldown until 18 November, and the next pre-flight reported
`no — in cooldown until 2026-11-18` instead of a match. **Reset and re-seed after every
rehearsal that reaches step 6.**

## 4. Signing in to the portal

The portal has a real sign-in at **`/<locale>/sign-in`** — username and password, no token to
mint. Four accounts exist, created by migration:

**The passwords come from `.env`, not from this document.** Since
`V19__unseed_portal_passwords.sql` no migration carries one: `PORTAL_ADMIN_PASSWORD` sets
`soborey`, `PORTAL_STAFF_PASSWORD` sets the three hospital accounts, and
`PortalPasswordBootstrap` writes the digests at startup. Set both before a demo, or nobody can
sign in — section 9.

| Username | Role | Hospital | Sees |
|---|---|---|---|
| `soborey` | ADMIN | — | every hospital, plus **Manage staff** |
| `calmette` | HOSPITAL | Calmette Hospital | that hospital only |
| `tepi` | HOSPITAL | National Blood Transfusion Center | that hospital only |
| `july` | HOSPITAL | Khmer-Soviet Friendship Hospital | that hospital only |

The rows are created by `V13__staff_password_login.sql` (admin), `V14__hospital_staff_login.sql`
(Calmette) and `V15__more_hospital_staff.sql` (the other two). Those migrations also seeded a
password, and `V16__unify_seeded_passwords.sql` made all four the same one — which meant one
string in the repository opened every portal account including the ADMIN.
`V19__unseed_portal_passwords.sql` replaced those four digests with hashes of random values
nobody holds. The accounts survive; the credential does not.

If sign-in says "Wrong username or password" on a fresh stack, read the backend log before
retyping anything: `portal password bootstrap: PORTAL_ADMIN_PASSWORD is not set` means exactly
what it says, and a value under 12 characters is refused with `REFUSED` rather than accepted.

**The board itself needs no account.** `/<locale>/portal` is public (DEC-009) — anyone can read
who needs blood, where and when. Signing in adds the staff actions on the same page: confirming a
donation, the recently-fulfilled section, and for an ADMIN the staff page. Open it signed out at
least once before a demo; explaining "and this part anyone can see" is half the pitch.

> ⚠ **Every password above is in the repository**, readable by anyone with the code. That is
> acceptable only while every account in this pilot is team-created test data. Section 9 has the
> one command that changes them, and it has to run before this app holds one real donor's record.

`PORTAL_DEV_JWT` is **gone** — removed from `.env.example` and `docker-compose.yml`. It was a
token pasted in by hand, shared by whoever had the file, owned by nobody, and impossible to revoke
from inside the product. `scripts/mint-portal-jwt.py` and its `.java` twin still exist for one
narrow job: minting a **DONOR** or **REQUESTER** token to poke the mobile API with `curl` without
running the app.

## 5. Adding staff after the first one (no SQL required)

The dev-JWT bridge above is only for standing up the very first `ADMIN` session locally.
Every staff account **after** that is provisioned through the app, not a migration:

1. The person signs in once via the mobile app as an ordinary donor/requester — this is
   what captures their `display_name` for the next step (TM-AUTH-001 E1).
2. An `ADMIN` opens **Manage staff** (top of the portal, ADMIN sessions only) at
   `/portal/staff`, picks that person by name from the dropdown, chooses `HOSPITAL` (with
   their hospital) or `ADMIN`, and submits.
3. They now have portal access — no password, no invite email, nothing stored beyond the
   name already captured at sign-in.

`V8__portal_access.sql`'s hand-run insert is now only a bootstrap for the first `ADMIN`,
the one account that has to exist before anyone can use step 2 on anyone else.

**The exception is an account with no mobile history at all.** The candidate dropdown is built from
users who have already signed in on the app, so a portal-only account — `tepi` and `july` are both
this — cannot be created through the page. Those come from a migration, following the pattern in
`V15__more_hospital_staff.sql`: username, BCrypt hash, `role = 'HOSPITAL'`, and a `hospital_id`
looked up by name.

## 6. Known gaps — say these before someone asks

- **The portal signs in with a username and password, not Google.** Deliberate, and worth saying
  before someone asks why it differs from the mobile app: ADR 0002 moved *donor* authentication to
  Google because a donor should not hold a password for an app they open three times a year. Portal
  staff are a handful of named accounts reaching a desktop browser with no phone in the loop, so
  they get credentials instead. No self-service sign-up, no password reset — an admin grants
  access, and a forgotten password is a new hash set by a migration.
- **A cold stack's portal is empty** until either the golden path has run once or
  `scripts/seed-demo-request.sql` has been applied (section 8.1). Run one of the two
  *before* the audience is watching — don't open the portal cold.
- **A rehearsed-on stack is the opposite problem.** On 2026-09-23 this database held 54 requests,
  48 of them cancelled leftovers against one hospital, and `scripts/metrics.sql` read 5.6%
  against a 70% target because of them. The board also showed CRITICAL requests dated three
  weeks earlier. `scripts/reset-demo-data.sql` clears the transactional rows and keeps the
  reference data; run it, then re-seed, before any demo that will show numbers.
- **`FR-SECURITY-001` (account/data deletion) is deferred**, on purpose, per `docs/scope.md`
  — say this only if pushed on privacy, and be clear it comes back in scope before any real
  donor (outside the team) touches the app.
- Eight other FRs are deferred by `docs/scope.md` (DEC-004) — point there rather than
  improvising a reason per feature.

### `docker compose up --build backend` drops the Firebase key

Found on 2026-09-23, an hour before a mobile rehearsal. Rebuilding one service by hand uses the
base file only:

```bash
docker compose up -d --build backend        # ⚠ no overlay — Google Sign-In then 503s
```

`scripts/dev-up.sh` adds `-f docker-compose.firebase.yml` when `.env` names a
`GOOGLE_APPLICATION_CREDENTIALS`; a bare `docker compose` command does not, and the container
comes up healthy with no key mounted. Everything a browser touches keeps working — the board, the
portal, the metrics — so nothing looks wrong until a phone tries to sign in and
`POST /auth/google` answers `503 AUTH_PROVIDER_UNCONFIGURED`.

Re-run `bash scripts/dev-up.sh` instead of rebuilding a single service, and check before trusting
it:

```bash
docker exec lifelinkkh-backend-1 sh -c 'echo $GOOGLE_APPLICATION_CREDENTIALS'
# /run/secrets/firebase-service-account.json  — empty means the overlay is missing

curl -s -X POST http://127.0.0.1:8080/api/auth/google \
  -H 'Content-Type: application/json' -d '{"idToken":"nonsense"}'
# {"error":{"code":"INVALID_ID_TOKEN"}}  — good: the verifier ran
# 503 AUTH_PROVIDER_UNCONFIGURED        — bad: no key, sign-in will fail on the device
```

## 7. If something's broken instead of empty

```bash
docker compose ps                        # everything should say "healthy"
docker compose logs --tail=60 backend    # or postgres / web
```

`scripts/verify-all.sh` runs every client's checks in one pass if you need to confirm
nothing regressed before the demo, not during it.

## 8. Testing every surface

Section 3 is the demo — one path, told as a story. This section is the opposite: how to get
into each of the four surfaces deliberately, including the two portal roles that behave
differently and are easy to confuse for one another.

### 8.1 Stack and data

```bash
bash scripts/dev-up.sh
curl -s http://127.0.0.1:8080/api/health              # {"status":"UP"}

# On a laptop that has been rehearsed on, clear the rehearsals FIRST. Reference data
# (districts, hospitals, staff accounts) survives; requests, matches, donations and donor
# accounts do not. Irreversible, local stacks only.
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink \
  < scripts/reset-demo-data.sql

# Three requests, three hospitals, all three urgency tiers, two with an accepted donor,
# aged 2 hours / 50 minutes / 20 minutes. Re-running refreshes those ages.
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink \
  < scripts/seed-demo-request.sql
```

The five PRD success metrics come out of the same database, in one run:

```bash
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink < scripts/metrics.sql
```

Read the `sample` column before quoting any percentage out loud — it carries the denominator,
and two of three requests accepted inside an hour is 67% of nothing. Metric 5 is FCM *accepting*
the send, not a phone displaying it; call it send-success, not delivery.

Postgres is on host port **5433**, not 5432 — a host PostgreSQL install usually owns 5432,
and the resulting "connection refused against the wrong database" is a confusing five
minutes. Inside the compose network the backend still reaches it at `postgres:5432`.

### 8.2 The board, signed out

```bash
open http://localhost:3000/en/portal      # or /km
```

No account. What proves you are genuinely signed out rather than looking at a cached page:

- **Staff sign-in** in the header, where a signed-in session shows a name and Sign out.
- Expanding a row lists accepted donors but offers **no confirm-donation control**.
- No **Recently fulfilled** section — that is a record of staff work, not a call for help.

### 8.3 Portal as HOSPITAL staff

Sign in at `/en/sign-in` as `tepi` (or `july`, or `calmette`) — password in section 4.

- The list shows **only that hospital's** requests. `tepi` sees 49, `july` sees 1, and the public
  board shows all 52 — the fastest way to tell which session you are in.
- The header shows the name and a grey **HOSPITAL STAFF** chip.
- **No "Manage staff" link**, and `/en/portal/staff` renders `admin-forbidden`.
- `GET /api/admin/staff` with that session answers **403**. The link's absence is not the control;
  `SecurityConfig` is.

### 8.4 Portal as ADMIN

Sign in as `soborey`.

- Every hospital's requests, not one — 52 against `july`'s 1.
- A red **ADMIN** chip, and **Manage staff** appears in the header.
- `/en/portal/staff` renders the grant form. Granting access is the real path for staff who already
  use the mobile app (section 5); accounts with no mobile history come from a migration instead.

### 8.5 Mobile — donor and requester

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api   # Android emulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api  # iOS simulator
```

`10.0.2.2` is the Android emulator's alias for the host. Getting this wrong looks exactly
like a backend that is down.

Use **two accounts** — the roles diverge at the shell, so one account cannot show both tab
sets. A donor gets Home / History / Me; a requester gets Home / Me and the oversized
"request blood" button.

Worth exercising deliberately, because none of it is on the golden path:

- **Me → language.** Switch to English and back. Every screen re-renders, the choice
  survives a restart, and the app re-registers `users.language` so push alerts follow —
  check with `SELECT language FROM users WHERE id = '<donor>';`.
- **Donor Home ordering.** With several open requests, CRITICAL sorts above URGENT above
  ROUTINE regardless of age, closest first within a tier, and anything already answered
  drops into "Already answered".
- **Offline behaviour.** Stop the backend (`docker compose stop backend`) and pull to
  refresh each list. Every one should offer a retry that works once the backend is back —
  not a bare error string.

### 8.6 Checking a role boundary directly

Faster than clicking, and it tests the control rather than the UI that hides it:

```bash
login() {
  curl -s -X POST -H 'Content-Type: application/json' \
    -d "{\"username\":\"$1\",\"password\":\"$2\"}" \
    http://127.0.0.1:8080/api/auth/portal/login |
    python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])'
}

STAFF=$(login tepi "$PORTAL_STAFF_PASSWORD")   # from .env — section 4

curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $STAFF" \
  http://127.0.0.1:8080/api/admin/staff                      # 403 — staff are not admins
curl -s -o /dev/null -w '%{http_code}\n' \
  http://127.0.0.1:8080/api/portal/requests                  # 401 — no session at all
curl -s -o /dev/null -w '%{http_code}\n' \
  http://127.0.0.1:8080/api/public/requests                  # 200 — the board is public
```

A wrong password and an unknown username both answer **401 `INVALID_CREDENTIALS`**, byte for byte
and in the same time. That is deliberate — anything that told them apart would enumerate the staff
list one guess at a time.

### 8.7 Automated checks

```bash
bash scripts/verify-all.sh          # every client, one pass
```

Or individually: `cd backend && ./mvnw verify` (needs Docker — Testcontainers starts a real
PostgreSQL), `cd frontend && npm test -- --run && npm run lint`, `cd mobile && flutter
analyze && flutter test`.

Backend output is worth piping to a file rather than reading through `tee`: `./mvnw -q test
| tee` has twice looked like a hang mid-run when it was Spring's console logging fighting
the pipe. A truncated tail is not a failure — re-run unpiped before believing it.

### 8.8 Symptoms that are not bugs

| What you see | What it actually is |
|---|---|
| Bounced to `/sign-in` mid-session | The session is one hour, matching the JWT (ADR 0007 has no refresh). Sign in again |
| Portal shows "Could not load the request list" while signed in | The backend is down or unreachable, not the session. `docker compose ps` |
| "Wrong username or password" and you are sure it is right | All four accounts share one password (section 4). If it still fails the row may predate `V16` — check `flyway_schema_history` |
| "Too many attempts. Wait a minute" | The per-IP limiter, 20/minute. Not a rejected password — the sign-in page tells these apart |
| Every portal route 500s right after a build | `npm run build` was run while `next dev` was live; they share `.next`. Stop dev, `rm -rf .next`, restart |
| Mobile can't reach anything on Android | `API_BASE_URL` points at `127.0.0.1`, which is the emulator itself. Use `10.0.2.2` |
| `POST /auth/google` answers 503 | No `GOOGLE_APPLICATION_CREDENTIALS` in `.env`. Everything else still serves |
| Portal list is empty | Cold stack. Seed it (8.1) or run the golden path once |

## 9. Setting and rotating the portal passwords

There is no seeded password any more. `V13`/`V14`/`V15` seeded one and `V16` unified it, so from
6 September until 23 September a single string in this repository opened all four portal accounts
— including the ADMIN that grants portal access and confirms donations.
`V19__unseed_portal_passwords.sql` replaced those digests with BCrypt hashes of random values
generated inside the database, which nobody has ever seen.

Passwords now come from the environment:

```bash
# .env — gitignored, never committed
PORTAL_ADMIN_PASSWORD=<at least 12 characters>   # soborey (ADMIN)
PORTAL_STAFF_PASSWORD=<at least 12 characters>   # calmette, tepi, july (HOSPITAL)
```

`PortalPasswordBootstrap` reads them at startup and writes the digests, so **rotating is editing
`.env` and restarting the backend**:

```bash
docker compose up -d --force-recreate backend
```

What it does and does not do, each one deliberate and covered by a test in
`PortalPasswordBootstrapTest`:

- **Unset sets nothing.** No default, no generated password printed to a log. The log says
  `PORTAL_ADMIN_PASSWORD is not set, so [soborey] cannot sign in`. A portal nobody can reach is a
  smaller problem than a portal everybody can.
- **Under 12 characters is refused**, logged at ERROR with `REFUSED`, and the account stays
  unopenable. A password short enough to read off a projector would be worse than the one this
  replaced.
- **A password already in place is left alone.** It compares before writing, so a restart does not
  rewrite four rows, and an admin who changed their own password through the product does not get
  it reset to the file's value on the next boot.
- **Each row keeps its own salt.** One value in `.env` still produces three different digests for
  the three hospital accounts, so cracking one does not open the others.
- **The value never reaches a log, an error message or a response.** Counts and usernames only.

One thing this does not fix: three people sharing `PORTAL_STAFF_PASSWORD` is three people with one
account, and the portal still has no password reset and no self-service change — an admin grants
access, and a forgotten password is `.env` plus a restart, or the UPDATE below. Both are
deliberate limits of a pilot whose accounts are all team-created; say so if asked.

### Setting one account's password by hand

Still the right tool for an account the bootstrap does not cover, or for rotating one account
without touching the others. BCrypt hashes cannot be written by hand, so generate one with the
app's own encoder:

```bash
cd backend
./mvnw -q dependency:build-classpath -Dmdep.outputFile=/tmp/cp.txt

cat > /tmp/Hash.java <<'JAVA'
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
public class Hash {
    public static void main(String[] args) {
        System.out.println(new BCryptPasswordEncoder().encode(args[0]));
    }
}
JAVA

java -cp "target/classes:$(cat /tmp/cp.txt)" /tmp/Hash.java 'the-new-password'
```

```bash
docker exec -i lifelinkkh-postgres-1 psql -U lifelink -d lifelink \
  -c "UPDATE users SET password_hash = '<paste-the-hash>' WHERE username = 'soborey';"
```

Three things worth getting right:

- **Quote the hash in single quotes.** A BCrypt digest contains `$`, which a shell will expand into
  nothing if the string is double-quoted — producing a truncated hash that verifies against no
  password at all, and an account nobody can sign in to.
- **One hash per account.** BCrypt salts per row, so reusing one digest across accounts undoes that
  and makes a single crack open all of them.
- **Do not edit V13/V14/V15/V16 instead.** Flyway records a checksum per migration file; changing
  one that has already run makes the next startup fail rather than applying the change. A new
  `V<n>` migration is the tool for a schema-level change, and `.env` plus a restart is the tool for
  a password.
- **A hand-set password survives the bootstrap** only if it differs from what is in `.env`; the
  bootstrap rewrites any account whose stored digest does not match its variable. Clear the
  variable if an account should be managed by hand.
