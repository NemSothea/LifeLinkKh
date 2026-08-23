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

1. **Account A** — Google Sign-In, register as donor: blood type, district, leave
   last-donation date blank (fresh donor → immediately eligible).
2. **Account B** — Google Sign-In, create an urgent request: matching blood type, a district
   near Account A's, urgency `CRITICAL`.
3. Matching + push fires. Account A gets a push notification within seconds (FCM). Open it.
4. Account A **accepts**.
5. Switch to the **web portal** (`http://localhost:3000/km` — Khmer by default, English via
   the language switcher top-right). Open the request row — Account A is listed as an
   accepted donor. Click **confirm donation**.
6. Back on Account A's app — donation history now shows the entry, eligibility flips to
   "next eligible in 56 days."

That loop — register, request, match, push, accept, confirm, history — is the whole product.
Everything else in `docs/scope.md`'s "8 FRs built" table supports one of these six steps.

## 4. Getting into the portal (temporary — read this)

The portal has **no Google Sign-In button yet** — no Firebase Web app is registered for it.
Until that's built, a session is minted directly for the backend's own JWT format:

```bash
# 1. get the seeded HOSPITAL user's id (once — id is stable across restarts, only
#    the token needs re-minting)
docker exec lifelinkkh-postgres-1 psql -U lifelink -d lifelink \
  -c "SELECT id FROM users WHERE role = 'HOSPITAL';"

# 2. mint a token (expires in 1 hour — re-run this before any demo, not the night before)
cd backend
./mvnw -q dependency:build-classpath -Dmdep.outputFile=/tmp/cp.txt
java -cp "target/classes:$(cat /tmp/cp.txt)" ../scripts/mint-portal-jwt.java \
  "$(grep ^JWT_SECRET ../.env | cut -d= -f2)" <hospital-user-id> HOSPITAL

# 3. put it in the root .env as PORTAL_DEV_JWT=<token>, then:
cd ..
docker compose up -d web
```

Full context: `scripts/mint-portal-jwt.java` header comment and
`docs/po/prototypes/web/PORTAL-open-requests/README.md`.

## 5. Known gaps — say these before someone asks

- **No portal login.** Hospital staff cannot sign in themselves today; step 4 above is a
  developer-only bridge. If asked "how does a hospital access this," the honest answer is
  "that's the one piece of FR-PORTAL-001 not finished — see the runbook."
- **No seed request data.** A freshly-started stack's portal shows the empty state until
  step 3 of the golden path has been run at least once. Run the golden path *before* the
  audience is watching, or narrate it live — don't open the portal cold.
- **`FR-SECURITY-001` (account/data deletion) is deferred**, on purpose, per `docs/scope.md`
  — say this only if pushed on privacy, and be clear it comes back in scope before any real
  donor (outside the team) touches the app.
- Eight other FRs are deferred by `docs/scope.md` (DEC-004) — point there rather than
  improvising a reason per feature.

## 6. If something's broken instead of empty

```bash
docker compose ps                        # everything should say "healthy"
docker compose logs --tail=60 backend    # or postgres / web
```

`scripts/verify-all.sh` runs every client's checks in one pass if you need to confirm
nothing regressed before the demo, not during it.
