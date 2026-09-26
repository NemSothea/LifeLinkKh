# Demo runbook

**Owner:** Tech Lead. Read this before any defense, sprint review, or ad-hoc "show me the app."
It is the golden path plus the known gaps — say the gaps out loud rather than hoping nobody
notices them live.

> **Rewritten 2026-09-26 for ADR 0009.** There is no Spring Boot backend, no PostgreSQL and no
> Docker any more. The app and the portal talk to Firebase (Firestore + Auth + Cloud Functions,
> region `asia-southeast1`, project `lifelinkkh`). Locally that means the **Firebase Emulator
> Suite**; for real pushes it means the **real project**. `firebase/README.md` is the up-to-date
> how-to for the Firebase side and this file does not repeat it; this file is the demo on top.

## 0. Pick the mode first

There are two ways to stand the demo up, and they differ in exactly one thing that matters on
stage: **whether a push arrives.**

| | Emulator stack (section 1) | Real project (section 2) |
|---|---|---|
| Data | Local Firestore + Auth emulators, wiped when they stop | `lifelinkkh` in the cloud, persistent |
| Matching | The real `onRequestCreated`, in the Functions emulator | The deployed Function |
| Pushes | **None.** FCM has no emulator; the Function tries real FCM and fails without credentials | Real FCM, to the real phones |
| Needs | Java 21, Node, no internet for the data (Google Sign-In on the phone still needs it) | Blaze plan, Functions deployed, internet on every device |
| Good for | Rehearsal, portal work, a demo where the push is narrated | The defense, if the alert arriving on a phone is the moment you want |

Why no pushes from the emulator: the Functions send through `firebase-admin` messaging. On a
`demo-` project (the tests) every push is written to the `_outbox` collection instead — that is
how the tests read exactly what a donor would receive. The app's emulator runs as project
`lifelinkkh` (the app is built for that id), so the Function takes the real-FCM branch and the
send fails for want of a credential. The match documents are still written, so the donor's app
still shows the request; only the notification is missing.

DEC-012 still holds either way: the defense runs from one machine. Firebase App Hosting is the
recommended home for the portal if it ever needs a public URL (same region and billing as the
rest); Vercel is acceptable for a class demo. Neither is required on the day.

## 1. Bring up the emulator stack

One-time, in `firebase/`:

```bash
cd firebase
npm install
(cd functions && npm install)
```

Then, every time — **terminal 1**, left running:

```bash
cd firebase
npm run emulators:app     # Firestore :8081 · Auth :9099 · Functions :5001 · UI :4000, project lifelinkkh
```

It needs **Java 21** (the emulators are a Java program). Wait for `All emulators ready`.

**Terminal 2** — the data. The emulators start empty and forget everything when they stop, so
this runs after every start:

```bash
cd firebase
npm run seed:app                                     # 14 districts + 5 hospitals
PORTAL_ADMIN_PASSWORD='<12+ chars>' npm run seed:admin:app   # the portal admin, soborey
npm run seed:demo                                    # the demo request, see below
```

`seed:demo` writes two O− donors in Doun Penh (Nem Sothea, Sok Dara), a requester (Chea Srey)
and one **CRITICAL AB+ request at Calmette**. The request goes through the real
`onRequestCreated` Function, which is why Functions must be running; the script waits for the
match, then has the first donor accept, so the portal has a donation to confirm. It deletes
`requests`, `matches` and `donations` first and it only ever talks to the emulator — it prints
`… donors alerted, 1 accepted — ready to confirm in the portal` when it worked, and
`onRequestCreated never ran` when the emulators were started without Functions.

**Terminal 3** — the portal:

```bash
cd frontend
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 \
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001 \
npm run dev
```

Set **all three or none**: one left set points the portal at an emulator and the others at the
real project, which reads as an empty or broken portal. Putting them in `frontend/.env.local`
(gitignored) saves typing; Next reads its own directory's env files, not the repo root's `.env`.

Confirm before doing anything else: the Emulator UI at http://localhost:4000 shows the seeded
collections, and http://localhost:3000/en/portal lists the Calmette request.

**The phones** — see section 3, with `--firestore-emulator`.

## 2. Or: the real project

Once per project (Tech Lead, needs the Blaze plan on `lifelinkkh`):

```bash
cd firebase
npx firebase deploy --only firestore,functions --project lifelinkkh    # rules, indexes, Functions
npm run seed -- --project lifelinkkh                                     # districts + hospitals
PORTAL_ADMIN_PASSWORD='<12+ chars>' npm run seed:admin -- --project lifelinkkh
```

The two seed commands need `GOOGLE_APPLICATION_CREDENTIALS` pointing at a service-account JSON
(`.env.example` explains where it lives and why it is never committed), and they refuse to run
if an emulator host variable is set — otherwise `--project lifelinkkh` would silently mean the
emulator. Before the Functions go live, set a **budget alert** on the billing account; a class
project stays inside the free tier, and the alert is what tells you it did not.

`seed:demo` is emulator-only by design (it deletes data). On the real project the demo request
is the one Account B posts on stage.

The portal against the real project:

```bash
cd frontend
FIREBASE_PROJECT_ID=lifelinkkh FIREBASE_API_KEY=<Web API key from the console> npm run dev
```

No emulator variables. The Web API key is not a secret (it identifies the project to Firebase
Auth's REST API), but restrict it to the Identity Toolkit API in Google Cloud.

The phones: section 3, **without** `--firestore-emulator`.

## 3. Run the mobile app

See `mobile/README.md` "Run it" for the one-time setup (`google-services.json`, debug SHA-1
registered in Firebase — Google Sign-In fails silently without it). The app takes no
`API_BASE_URL` any more; it talks to Firebase directly. Then:

```bash
bash scripts/demo-mobile.sh                         # Android emulator — boots the AVD if none runs
bash scripts/demo-mobile.sh emulator <avd>          # naming the AVD
bash scripts/demo-mobile.sh usb                     # physical Android on a cable
bash scripts/demo-mobile.sh ios                     # booted iOS simulator — no push, never the donor
# add --firestore-emulator to any of them for the emulator stack
```

The script exists because the emulator's address differs per device, and a wrong one looks
exactly like an empty database:

| Device | `FIRESTORE_EMULATOR` | Why |
|---|---|---|
| Android emulator | `10.0.2.2:8081` | The emulator's alias for this Mac |
| USB Android phone | `127.0.0.1:8081`, after `adb reverse tcp:8081 tcp:8081` | A cabled phone reaches the Mac only through the reverse tunnel |
| iOS simulator | `127.0.0.1:8081` | Shares the Mac's loopback |

By hand, that is `cd mobile && flutter run --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081`
(or plain `flutter run` for the real project). The script also cycles airplane mode on an
Android device before launch — see "dead FCM connection" in section 7.

Only Firestore is redirected. **Sign-in is always real Google Sign-In against Firebase Auth**,
so the phone needs internet even on the emulator stack, and the donor's `users/{uid}` document
lives in whichever Firestore the app points at.

Use **two accounts** (two devices) — a donor and a requester. Any signed-in user may post a
request (a donor whose relative needs blood is the likely case), but one account for both roles
makes the demo confusing to watch, and it matches nobody (section 4, trap 1).

## 4. The golden path (what to actually show)

**The values below are pinned, not examples.** Matching is a filter chain, and a request that
passes none of it is not an error anywhere in the product: the request is written, the portal
lists it, and the donor's phone stays silent. `FR-MATCH-002` (retry with a wider radius) is
deferred, so nothing widens and nothing on screen explains the silence. Improvising a blood type
in front of an audience is how that happens.

| Step | Field | Pinned value | Why this one |
|---|---|---|---|
| 1 | **Account A** — blood type | **O−**, or the donor's real type | O− is the universal donor, so nothing can miss it. But the pin that actually protects this demo is the patient's type below — with an AB+ patient, **any** donor type matches |
| 1 | Account A — district | **Doun Penh (1202)** | Calmette's own district. If the donor grants GPS, the distance is ~0 km, far inside the 10 km radius |
| 1 | Account A — last donation | **leave blank** | Blank means never donated, which means immediately eligible. Any date inside 56 days removes the donor from every match |
| 2 | **Account B** — hospital | **Calmette Hospital** | Seeded by `npm run seed:app`, and the district above is chosen against it |
| 2 | Account B — patient type | **AB+** | **The one value not to improvise.** AB+ is the universal recipient — it accepts all eight donor types. Change it and compatibility becomes a real filter again |
| 2 | Account B — urgency | **CRITICAL** | Top tier reads clearest on the portal list, and urgency does not affect matching |

1. **Account A** — Google Sign-In, register as donor with the values above.
2. **Account B** — Google Sign-In, create an urgent request with the values above.
3. `onRequestCreated` matches and pushes. On the real project Account A gets a notification
   within seconds; on the emulator stack the request appears in Account A's matches with no
   notification — say so, don't wait for it.
4. Account A **accepts**. `onMatchAnswered` bumps the accepted count, adds the donor to the
   public board row, and pushes "A donor accepted your request" to Account B (`FR-NOTIFY-003`,
   real project only).
5. Switch to the **web portal** (`http://localhost:3000/km` — Khmer by default, English via the
   switcher top-right). Sign in as the admin `soborey` (section 5), open the request row —
   Account A is listed as an accepted donor. Click **confirm donation** (the `confirmDonation`
   callable, admin only).
6. Back on Account A's app — donation history shows the entry, eligibility flips to "next
   eligible in 56 days."

That loop — register, request, match, accept, confirm, history — is the whole product.
Everything else in `docs/scope.md`'s "8 FRs built" table supports one of these six steps.

### Prove the match before the room does

There is no pre-flight script any more (`scripts/preflight-match.sql` went with Postgres). Do
it by eye in the Emulator UI (http://localhost:4000 → Firestore), or the Firebase console on the
real project, after Account A registers and before Account B posts:

- `donors/{uid}` — `bloodType` compatible with the patient, `isAvailable: true`,
  `lastDonationDate` null or 56+ days ago, and either no coordinates or coordinates near Calmette.
- `users/{uid}` — `fcmToken` is **not null**. Null means no push, whatever else matches.

After the request is posted, `matches/{requestId}_{donorUid}` existing is the proof the Function
matched; the Functions emulator's terminal logs each run. The `seed:demo` donors always have
`fcmToken: null` — they are documents, not installs, and never receive a push. That is expected.

Who can give to whom, if the question comes up mid-demo (ADR 0004 — whole blood and red cells
only; the table is a constant in `firebase/functions/src/matching.js`):

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

### The ways this goes silent

Each one is a filter in `selectCandidates` (`firebase/functions/src/matching.js`), and none of
them produces an error the audience can see.

1. **One account playing both roles.** A donor never matches their own request. Deliberate, and
   the fastest way to a silent demo. Two accounts, always.
2. **Step 6 already ran today.** Confirming a donation starts the 56-day cooldown, and that donor
   is then excluded from every match. **Rehearsing the full loop twice with the same donor gives
   a silent second run.** On the emulator, restart the emulators and re-seed; on the real
   project, use a different donor account for the rehearsal.
3. **Donor marked unavailable.** `isAvailable` is a toggle in the app, and a rehearsal may have
   left it off.
4. **GPS granted from too far out.** A donor with no coordinates matches regardless and simply
   ranks last; a donor **with** coordinates is cut at 10 km (`RADIUS_KM`). Granting location
   from outside central Phnom Penh is therefore *worse* than declining it.
5. **No FCM token on that install.** The match is still written and the portal still shows the
   request — only the push is missing, which looks identical to "matching is broken" from the
   audience's side. Tokens are per-install: a reinstalled device has a new one.

Sixth, not a matching rule but the same silent shape: `REQUEST_RATE_LIMIT` is 5 requests per 10
minutes per creator. The sixth request in a long rehearsal is closed by the Function as
`CANCELLED` with `cancelReason: RATE_LIMITED` and alerts nobody.

Also a cap, not a failure: at most 25 donors are notified per request (ADR 0008), nearest first.

## 5. Signing in to the portal

v1 has **one portal account, the admin `soborey`** (DEC-014). No hospital staff, no staff page;
the old `/portal/staff` and `/portal/admin` paths redirect to `/portal`. Sign in at
**`/<locale>/sign-in`** with username `soborey` and the password you gave `PORTAL_ADMIN_PASSWORD`
when seeding. This repository is **public** — the password never goes into this file.

Under the hood the username maps to `soborey@portal.lifelink.invalid` in Firebase Auth (the
`.invalid` TLD means no mail can ever be sent to it), and access needs both the `ADMIN` claim
**and** an `admins/{uid}` record. The seed script writes both; the rules check both on every read.

If sign-in says "Wrong username or password" on a fresh emulator stack, the usual cause is that
`seed:admin:app` has not run since the emulators last started — the Auth emulator forgets the
account on every stop. A password under 12 characters was `REFUSED` by the seed, not stored.

**The board itself needs no account.** `/<locale>/portal` is public (DEC-009) — anyone can read
who needs blood, where and when. Signing in adds the admin actions on the same page: confirming a
donation and the recently-fulfilled section. Open it signed out at least once before a demo;
"and this part anyone can see" is half the pitch.

## 6. Known gaps — say these before someone asks

- **The portal signs in with a username and password, not Google.** ADR 0002 moved *donor*
  authentication to Google because a donor should not hold a password for an app they open three
  times a year. The portal is one named admin account on a desktop browser. No self-service
  sign-up and no password reset.
- **Hospital staff cannot confirm their own donations** (DEC-014) — the admin does it for every
  hospital. Staff roles are a v2 decision.
- **The emulator stack delivers no pushes** (section 0). If the demo runs on it, narrate the
  alert rather than waiting for it.
- **`FR-SECURITY-001` (account/data deletion) is deferred**, on purpose, per `docs/scope.md`
  — say this only if pushed on privacy, and be clear it comes back in scope before any real
  donor (outside the team) touches the app.
- Eight other FRs are deferred by `docs/scope.md` (DEC-004) — point there rather than
  improvising a reason per feature.

## 7. Devices and push — what goes wrong that is not code

**Put the donor on Android.** The iOS Simulator has no APNs, so `FirebaseMessaging.getToken()`
returns null there — sign-in still works, which is why nothing looks wrong. That account simply
stores no token and never receives the alert. A donor on iOS needs a physical device. Since
`FR-NOTIFY-003` the requester gets a push too, so put the requester on a physical phone or a
second Android emulator if the acceptance alert is part of the demo. The Android AVD must be a
**Google Play** image (`tag.id=google_apis_playstore`); a plain AOSP image has neither Play
services nor FCM.

**One token per account, last device wins.** The app re-registers its token on open, so open
the app on each demo device **last**, after any other device has used the same account.

### An emulator restored from a snapshot can hold a dead FCM connection

Found on 2026-09-25. The server logged the send — FCM had accepted the message — and nothing
reached the Android emulator, foreground or background. Play services still reported
`connected=mtalk.google.com` but `Seen good heartbeat in last connection? false`: the socket
restored from yesterday's snapshot was dead and nothing had noticed. The queued messages arrived
the moment the network was cycled:

```bash
adb shell cmd connectivity airplane-mode enable; sleep 3
adb shell cmd connectivity airplane-mode disable
# then confirm delivery, not just the send:
adb shell dumpsys activity service com.google.android.gms/.gcm.GcmService | grep kosign
```

`scripts/demo-mobile.sh` does the airplane-mode cycle itself on every Android launch. A logged
send proves FCM took the message, not that the device got it — the `grep kosign` line with
today's timestamp is the proof.

### Untethered phones

On the real project the phones need only internet — no cable, no fixed IP, no tunnel. Use your
own phone's hotspot rather than the room's Wi-Fi: venue networks fail in ways you cannot fix from
the stage. Sign both phones in before the room fills, and keep the fallback recording
(demo-script §8).

An iPhone as a demo device: open `mobile/ios/Runner.xcworkspace` in Xcode once, Runner → Signing
& Capabilities → Team: your Personal Team (free Apple ID) — do not commit the team id that writes
into `project.pbxproj`. Then `cd mobile && flutter run --release -d <iphone-id>` with the phone on
USB the first time, and trust the developer certificate in Settings → General → VPN & Device
Management. **A free Personal Team install expires after 7 days**: install within the week of the
demo. No APNs without an Apple Developer account (DEC-006), so an iPhone never receives a push —
make it the requester and narrate the acceptance beat from the count on its request.

## 8. Testing every surface

Section 4 is the demo — one path, told as a story. This section is how to get into each surface
deliberately.

### 8.1 Data and metrics

Fresh data on the emulator is a restart: stop `emulators:app` (Ctrl-C), start it again, re-run
the three seeds in section 1. `seed:demo` alone clears requests, matches and donations and
re-creates the one demo request, which is enough between rehearsals.

The five PRD success metrics, in one run:

```bash
cd firebase
npm run metrics                              # the emulator
npm run metrics -- --project lifelinkkh      # the real project (GOOGLE_APPLICATION_CREDENTIALS)
```

Read the `sample` column before quoting any percentage out loud — it carries the denominator,
and two of three requests accepted inside an hour is 67% of nothing. Metric 5 is FCM *accepting*
the send, not a phone displaying it; call it send-success, not delivery.

### 8.2 The board, signed out

```bash
open http://localhost:3000/en/portal      # or /km
```

What proves you are genuinely signed out rather than looking at a cached page:

- **Admin sign-in** in the header, where a signed-in session shows a name and Sign out.
- Expanding a row lists accepted donors but offers **no confirm-donation control**.
- No **Recently fulfilled** section.

### 8.3 Portal as ADMIN

Sign in as `soborey`. Every hospital's requests, the confirm-donation control on accepted donors,
the recently-fulfilled section, and a password page at `/<locale>/portal/password` for the admin
to change their own password.

The boundary is the rules, not the UI, and the quickest proof is to revoke: in the Emulator UI,
delete `admins/{uid}` for `soborey` and reload the portal — the next read is refused although
the ID token still carries the `ADMIN` claim. Re-run `seed:admin:app` to put it back. The rules
tests (`firebase/rules-tests/`) assert the same thing, along with "a claim alone is no access"
and "a record alone is no access".

### 8.4 Mobile — donor and requester

Two accounts — the roles diverge at the shell, so one account cannot show both tab sets. A donor
gets Home / History / Me; a requester gets Home / Me and the oversized "request blood" button.

Worth exercising deliberately, because none of it is on the golden path:

- **Me → language.** Switch to English and back. Every screen re-renders, the choice survives a
  restart, and `users/{uid}.language` updates so push alerts follow — check it in the Emulator UI.
- **Donor Home ordering.** With several open requests, CRITICAL sorts above URGENT above ROUTINE
  regardless of age, closest first within a tier, and anything already answered drops into
  "Already answered".
- **Offline behaviour.** Put the device in airplane mode and pull to refresh. Firestore's client
  cache serves what was already read, and every list should recover once the network is back —
  not end on a bare error string.

### 8.5 Automated checks

```bash
bash scripts/verify-all.sh          # every client, one pass — same steps CI runs
```

Rules tests, Functions unit and emulator tests, web lint/types/tests, `flutter analyze` and
`flutter test`. Individually: `cd firebase && npm run test:rules`,
`cd firebase/functions && npm test && npm run test:emulator`,
`cd frontend && npm run lint && npx tsc --noEmit && npm test -- --run`,
`cd mobile && flutter analyze && flutter test`. Run them before the demo, not during it.

### 8.6 Symptoms that are not bugs

| What you see | What it actually is |
|---|---|
| Bounced to `/sign-in` mid-session | The session cookie lasts one hour, like the Firebase ID token it holds. Sign in again |
| Portal shows "Could not load the request list" | The emulators are not running, or only some of the three emulator variables are set (section 1) |
| "Wrong username or password" and you are sure it is right | The Auth emulator forgot the admin on its last stop — re-run `seed:admin:app` |
| "Too many attempts. Wait a minute" | Firebase Auth's own per-account lockout (`TOO_MANY_ATTEMPTS_TRY_LATER`), not a rejected password |
| Every portal route 500s right after a build | `npm run build` was run while `next dev` was live; they share `.next`. Stop dev, `rm -rf .next`, restart |
| Mobile shows an empty app on the emulator stack | Wrong `FIRESTORE_EMULATOR` for that device — `127.0.0.1` from an Android emulator is the emulator itself. Use `scripts/demo-mobile.sh` |
| The match exists, no notification arrived | Emulator stack (no pushes, section 0), `fcmToken` null, or a dead FCM socket (section 7) |
| `seed:demo` says `onRequestCreated never ran` | Emulators started without Functions — use `npm run emulators:app`, not `npm run emulators` |
| Emulators fail to start | Java older than 21 on the `PATH` |

## 9. Setting and rotating the admin password

There is no password in this repository, and none in Firestore — Firebase Auth holds it.
`firebase/seed/admin.mjs` sets it from `PORTAL_ADMIN_PASSWORD`, following the same three rules
the old Spring bootstrap did:

- **Unset sets nothing.** No default, no generated password printed to a log.
- **Under 12 characters is refused**, and the account is not created. A password short enough to
  read off a projector would be worse than none.
- **A password already in place is left alone** — the admin may have changed it on
  `/portal/password`. Pass `--reset-passwords` to rotate it to the variable's value:

```bash
cd firebase
PORTAL_ADMIN_PASSWORD='<new, 12+ chars>' npm run seed:admin:app -- --reset-passwords          # emulator
PORTAL_ADMIN_PASSWORD='<new, 12+ chars>' npm run seed:admin -- --project lifelinkkh --reset-passwords   # real
```

The claim and the `admins/{uid}` record are put right on every run either way. **To end an
admin's access**, delete `admins/{uid}` (the rules refuse them on the next read, before the
token expires) and disable the user in the Firebase console. Adding a second admin is an
operator step, not a page (DEC-014).

If you are projecting, type a password you are willing to have watched, and rotate it afterwards.
