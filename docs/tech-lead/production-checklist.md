# Production checklist — LifeLink on the real Firebase project

**Owner:** Tech Lead. Takes LifeLink from the emulators to the real `lifelinkkh` project that
donors and families in Phnom Penh would actually use. Work top to bottom; each section assumes the
ones above it are done. Tick the boxes in a copy, not here.

- **Part A–E: technical**, about a day of work, mostly waiting on consoles.
- **Part F: launch readiness.** Not technical, and several items are **blockers for a public
  launch** that no code change removes.
- **The Play Store release** is its own runbook: [`deploy-runbook.md`](deploy-runbook.md). It
  needs Part A–C done first.

Everything runs from the branch `feat/firebase-backend`. It is not merged into `main`, by decision.

---

## Part A — the Firebase project (one time)

- [ ] **Blaze plan** on `lifelinkkh` (console → Usage and billing). Cloud Functions do not run on
  Spark. A card is required; the pilot should stay inside the free usage.
- [ ] **Budget alert** in Google Cloud Billing → Budgets & alerts: budget **$5/month**, alerts at
  50%, 90% and 100%, emailed to the Tech Lead. A budget alerts; it does not stop spending. The real
  brake is `maxInstances: 1` on the Functions (already set) and on App Hosting (`apphosting.yaml`).
- [ ] **Firestore database**: Native mode, location **`asia-southeast1` (Singapore)**, the same
  region as the Functions.

  > **The location cannot be changed later.** A wrong choice means a new project. Check it twice.
- [ ] **Point-in-time recovery** on the database (Firestore → Disaster recovery), 7 days. Also add
  a **daily backup schedule** with 7-day retention. Both cost cents at pilot size. Without them, a
  bad rules deploy or a buggy Function that overwrites data cannot be undone.
- [ ] **Authentication → Sign-in method:**
  - **Google** enabled. This is the app's sign-in.
  - **Email/Password** enabled. This is the portal admin's sign-in. Leave "Email link" off.
  - **Email enumeration protection** on (the default for new projects).
- [ ] **Android app registered** with package `com.kosign.lifelinkkh`, and `google-services.json` in
  `mobile/android/app/` (already true for development). The release SHA-1s come in
  [`deploy-runbook.md`](deploy-runbook.md) Step 4 and Part E below.

## Part B — Rules, indexes and Functions

From `firebase/`, logged in (`npx firebase login`):

- [ ] Every check green first: `bash scripts/verify-all.sh` from the repo root. Deploy only from a
  clean, committed tree, so what runs in production is a commit you can name.
- [ ] Deploy:

  ```bash
  cd firebase
  npx firebase deploy --only firestore,functions --project lifelinkkh
  ```

  `firestore` covers `firestore.rules` and `firestore.indexes.json`. The first Functions deploy
  asks to enable Cloud Build, Artifact Registry and Eventarc. Say yes. It takes several minutes.
- [ ] Console → Functions shows **five**, all in `asia-southeast1`, runtime Node 22:
  `onRequestCreated`, `onRequestApproved`, `onMatchAnswered`, `reviewRequest`, `confirmDonation`.
- [ ] Console → Firestore → Indexes: all five composite indexes are **Enabled**, not "Building".
  A query against a building index fails, and the app shows it as a load error.
- [ ] Console → Firestore → Rules: the published rules are the ones from this commit (check the
  timestamp).

**Rollback.** Rules: the console keeps the rules history, so republish the previous version.
Functions: `git checkout <previous commit> -- firebase/functions` and deploy again. There is no
one-click Functions rollback.

## Part C — Seed data and the admin account

The seed scripts write with the Admin SDK, so they need a service-account key. That key is the
most dangerous file in this project.

- [ ] Console → Project settings → Service accounts → **Generate new private key**. Save it as
  `secrets/firebase-service-account.json` (the `secrets/` directory is gitignored).
- [ ] With **no** emulator variables set in this shell:

  ```bash
  cd firebase
  export GOOGLE_APPLICATION_CREDENTIALS="$PWD/../secrets/firebase-service-account.json"
  npm run seed -- --project lifelinkkh                                   # 14 districts, 5 hospitals
  PORTAL_ADMIN_PASSWORD='<16+ chars, from a password manager>' \
    npm run seed:admin -- --project lifelinkkh                           # soborey
  npm run metrics -- --project lifelinkkh                                # reads work; all zeros
  ```

  Both seed scripts refuse to run against a real project if an emulator variable is set.
- [ ] **Never run `seed:demo` against the real project.** It is emulator-only by design because it
  deletes requests, matches and donations.
- [ ] Revoke the key when done (Service accounts → Manage keys → delete) unless you need `metrics`
  again soon. Generate a fresh one next time. A key left on a laptop is a copy of the whole
  database waiting to leak.
- [ ] Store the admin password in a password manager, not in `.env` on a shared machine.

## Part D — The portal on App Hosting

The portal runs on **Firebase App Hosting**: same project, same bill, and a server near
Cambodia. Vercel works too (Root Directory `frontend`, the same two variables, region `sin1`), but
its free plan is for non-commercial use only.

- [ ] Console → App Hosting → **Create backend**:
  - Connect the GitHub repository. Root directory **`frontend`**. Live branch
    **`feat/firebase-backend`**.
  - Region: **`asia-southeast1`** if it is offered. Otherwise pick the nearest Asian region and
    accept a few hundred milliseconds per Firestore call. Check the list in the console; the
    supported regions change.
- [ ] The Web API key, as an App Hosting secret (the name `apphosting.yaml` expects):

  ```bash
  npx firebase apphosting:secrets:set firebase-web-api-key --project lifelinkkh
  ```

  Paste the key from Project settings → General → Web API key. Grant the backend access when
  asked.
- [ ] **Restrict that key** in Google Cloud → APIs & Services → Credentials. Set API restrictions
  to **Identity Toolkit API** only. The portal uses it for nothing else, so a leaked key can then
  only reach the sign-in endpoint.
- [ ] The first rollout is triggered by a push to the live branch (or "Create rollout" in the
  console). The build reads `frontend/apphosting.yaml`.
- [ ] On the App Hosting URL (`https://<backend>--lifelinkkh.<region>.hosted.app`):
  - [ ] `/km` loads, and its footer health line says reachable. That is a real read of Firestore.
  - [ ] `/km/portal` signed out shows the board (empty is fine).
  - [ ] Sign in as `soborey`. The header shows Soborey · ADMIN, and the "Waiting for review"
    queue is absent when there is nothing to review.
  - [ ] A wrong password says "wrong username or password", not an error page.
- [ ] Optional: a custom domain (App Hosting → Settings → Domains). The session cookie is set by
  the portal's own server, so no Firebase "authorized domains" change is needed.

## Part E — End-to-end on the real project

Two real Android phones, both installed from the **same** build. A Play internal-testing install
must use Play's signing key. See the note below.

- [ ] **Account A** (donor): Google sign-in, register O−, district Doun Penh, no last donation,
  push allowed. Firestore → `users/{uid}` has an `fcmToken`.
- [ ] **Account B** (requester): post CRITICAL AB+ at Calmette. The app shows **"Sent for
  review"**. Firestore → `requests/{id}` is `PENDING`, and no `matches` exist.
- [ ] **Portal**: the request is under **Waiting for review** with B's phone number. Approve it.
- [ ] Account A gets the **alert push** within seconds. Account B gets **"Your request was
  approved"**.
- [ ] Account A accepts. Account B gets **"A donor accepted your request"**. The public board
  shows 1 accepted.
- [ ] Portal: **Confirm donation**. The request moves to Recently fulfilled. Account A's history
  shows the donation, and eligibility shows 56 days.
- [ ] Post a second request from B and **Reject** it with a reason. B sees the reason in the app.
  The request never appears on the public board.
- [ ] `npm run metrics -- --project lifelinkkh` shows 1 donor, 2 requests and 1 donation.
- [ ] Console → Functions → Logs: no errors, apart from the FCM "token not registered" warnings
  the code expects.
- [ ] Clean up: cancel or leave the test requests. Don't delete documents by hand in the console,
  because the metrics count them.

> **Google sign-in on a Play install.** Play re-signs the app with its own key, so a
> Play-installed build has a **different SHA-1** from the one you built. Copy the **App signing
> key** SHA-1 (and SHA-256) from Play Console → Setup → App integrity into Firebase → Project
> settings → Android app, then download `google-services.json` again. Without this, Google sign-in
> fails on every Play install with a generic error, while your own debug build works fine.

## Part F — Launch readiness (before anyone outside the team uses it)

Everything in Part A–E makes the app *work* for real. This part makes it *fit* for real, and these
items do not come from code.

**Blockers for a public Play Store listing:**
- [ ] **Privacy policy** at a public URL. Say what is collected (name, blood type, district,
  optional GPS, phone number on requests, FCM token), why, who sees it (the donor's contact only
  goes to a family after the donor accepts; the admin sees request contacts), and how to delete
  it. Link it in the app and on the Play listing.
- [ ] **Account deletion**, both in the app and through a web link. Google Play requires both for
  any app with accounts. **Not built yet.** It needs a Function that deletes `users`, `donors`, the
  user's `matches` and `requests/*/private/contact`, and the Auth user, and decides what to keep of
  `donations` (anonymised) so the metrics stay honest. This needs its own DEC.
- [ ] **Play Console → Data safety** form, consistent with the privacy policy. Blood type counts
  as health information: declare it.

**Blockers for real use, whatever the store says:**
- [ ] **Review hours (DEC-015).** A request nobody reviews alerts nobody. Decide who is on duty
  and when, and say it in the app ("requests are reviewed 7:00–22:00"), so a family at 2 a.m. knows
  to call the hospital directly.
- [ ] **A partner** — the National Blood Transfusion Center or one hospital — who expects LifeLink
  donors and can confirm that a request is real when the admin calls. Without one the admin has no
  way to verify anything.
- [ ] **A safety line in the app** where a donor sees the family's phone number: "LifeLink never
  asks for money. Donate only at the hospital." Scammers aim at exactly this moment.
- [ ] **Medical disclaimer.** The 56-day rule is only a reminder. The hospital screens every
  donor, and the app is not medical advice.

**Should do early:**
- [ ] A second admin account for the day `soborey` is unavailable. It needs an `admins/{uid}`
  record and the claim. Extend `seed/admin.mjs` rather than editing by hand.
- [ ] Watch the budget and the Functions logs weekly for the first month.
- [ ] The portal shows "Could not load" to an admin whose access was revoked. Make it send them
  to sign in instead (known gap).
- [ ] iOS: out of scope (DEC-006). An iOS release would need an Apple Developer account and an
  APNs key uploaded to Firebase, or no iPhone ever receives a push.

---

## Related

- [`deploy-runbook.md`](deploy-runbook.md) — signed AAB and Play Store internal testing.
- [`local-development.md`](local-development.md) — the emulator stack.
- [`firebase/README.md`](../../firebase/README.md) — every Firebase command.
- ADR 0009, DEC-012 (demo first), DEC-014 (admin-only portal), DEC-015 (review before alert).
