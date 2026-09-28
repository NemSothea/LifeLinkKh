# Production checklist — LifeLink on the real Firebase project

**Owner:** Tech Lead. Takes LifeLink from the emulators to the real `lifelinkkh` project that
donors and families in Phnom Penh would actually use. Work top to bottom; each section assumes the
ones above it are done. Tick the boxes in a copy, not here.

- **Part A–E: technical**, about a day of work, mostly waiting on consoles.
- **Part F: launch readiness.** Not technical, and several items are **blockers for a public
  launch** that no code change removes.
- **The app is a sideloaded APK**, not on the Play Store, until 500 users:
  [`deploy-runbook.md`](deploy-runbook.md) **Path A**. It needs Part A–C done first. Path B (Play)
  is kept for later.

Everything runs from the branch `feat/firebase-backend`. It is not merged into `main`, by decision.

---

## Part A — the Firebase project (one time)

> **Cost target: $0 a month.** LifeLink is a free app, and the rule is to pay nothing until it
> has more than **500 users**; then decide again with real numbers from `npm run metrics` and the
> billing page. Everything below is chosen to stay inside the free allowances.

- [ ] **Blaze plan** on `lifelinkkh` (console → Usage and billing). Cloud Functions do not run on
  the free Spark plan at all, and without them there is no matching, no push and no review. Blaze
  asks for a card but **includes the same free allowance as Spark** and charges only above it. At
  pilot size that should never happen:

  | | Free each month (roughly) | LifeLink at 500 users |
  |---|---|---|
  | Firestore | 50,000 reads/day, 20,000 writes/day, 1 GB | thousands of reads a day |
  | Cloud Functions | 2,000,000 calls | hundreds to a few thousand |
  | FCM push | unlimited | — |
  | Auth (Google, password) | 50,000 monthly users | 500 |

  Check the current numbers on the Blaze pricing page before you enter the card; Google changes
  them.
- [ ] **Budget alert at $1** in Google Cloud Billing → Budgets & alerts: budget **$1/month**,
  alerts at 1% (the first cent), 50% and 100%, emailed to the Tech Lead. With a $0 target, any
  charge at all is news. A budget only alerts; it does not stop spending. The real brake is
  `maxInstances: 1` on the Functions (already set).
- [ ] **Artifact cleanup.** The first Functions deploy (Part B) asks whether to set a cleanup
  policy for old build images. Say **yes** (keep 1 day). Build images left to pile up are the most
  likely way a "free" project earns its first charge.
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
- [ ] Console → Functions shows **six**, all in `asia-southeast1`, runtime Node 22:
  `onRequestCreated`, `onRequestApproved`, `onMatchAnswered`, `reviewRequest`, `confirmDonation`,
  `deleteAccount`.
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
  PORTAL_ADMIN_USERNAME=nemsothea PORTAL_ADMIN_NAME='Nem Sothea' \
  PORTAL_ADMIN_PASSWORD='<16+ chars, from a password manager>' \
    npm run seed:admin -- --project lifelinkkh                           # the admin
  npm run metrics -- --project lifelinkkh                                # reads work; all zeros
  ```

  Both seed scripts refuse to run against a real project if an emulator variable is set.
- [ ] **Never run `seed:demo` against the real project.** It is emulator-only by design because it
  deletes requests, matches and donations.
- [ ] Revoke the key when done (Service accounts → Manage keys → delete) unless you need `metrics`
  again soon. Generate a fresh one next time. A key left on a laptop is a copy of the whole
  database waiting to leak.
- [ ] Store the admin password in a password manager, not in `.env` on a shared machine.

## Part D — The portal on Vercel (free)

The portal runs on **Vercel's free Hobby plan**, which fits a free, non-profit service with no ads
and no payments. Vercel's server only holds the Web API key, which is not a secret; there is no
Firebase admin key on it (`frontend/src/lib/api/client.ts` explains why). Firebase App Hosting is
the alternative (see the end of this part), but it bills through Cloud Run and Cloud Build, so it
is kept for when the 500-user decision is made.

- [ ] vercel.com → **Add New → Project** → import the GitHub repository.
  - **Root Directory: `frontend`**. Framework preset: Next.js (detected).
  - **Production Branch: `feat/firebase-backend`** (Settings → Git after import). It is not merged
    into `main`, by decision.
- [ ] **Environment Variables** (Production), exactly these, **and no `*_EMULATOR_HOST`**:

  | Name | Value |
  |---|---|
  | `FIREBASE_PROJECT_ID` | `lifelinkkh` |
  | `FIREBASE_API_KEY` | Firebase → Project settings → General → Web API key |
  | `SUPPORT_EMAIL` | the monitored address for deletion requests (DEC-016) |
  | `APK_DOWNLOAD_URL` | LifeLink's page on `https://kosignstore.wecambodia.com/` (unset: GitHub Releases) |
  | `APK_CERT_SHA256` | optional: the signing certificate SHA-256 `build-release-apk.sh` prints, shown on `/download` |

- [ ] **Function region: Singapore (`sin1`)**. This is `frontend/vercel.json`, so nothing needs
  setting by hand. The portal's server calls Firestore several times per page, and from Vercel's
  default US region each call would cross the Pacific twice.
- [ ] **Restrict the API key** in Google Cloud → APIs & Services → Credentials. Set API
  restrictions to **Identity Toolkit API** only. The portal uses it for nothing else, so a leaked
  key can then only reach the sign-in endpoint.
- [ ] Deploy (Vercel builds on every push to the production branch). On the
  `https://<project>.vercel.app` URL:
  - [ ] `/km` loads, and its footer health line says reachable. That is a real read of Firestore.
  - [ ] `/km/portal` signed out shows the board (empty is fine).
  - [ ] Sign in as `nemsothea`. The header shows Nem Sothea · ADMIN, and the "Waiting for review"
    queue is absent when there is nothing to review.
  - [ ] A wrong password says "wrong username or password", not an error page.
  - [ ] `/km/delete-account` shows the support address, not "not set up".
  - [ ] `/km/download` offers the APK, and names the version once `npm run release` has run.
- [ ] Optional: a custom domain (Vercel → Settings → Domains). The session cookie is set by the
  portal's own server, so no Firebase "authorized domains" change is needed.

**Later — Firebase App Hosting instead of Vercel.** Same project and bill, server in the same
region as Firestore. `frontend/apphosting.yaml` is ready: create a backend in the console (root
`frontend`, live branch `feat/firebase-backend`, region `asia-southeast1` if offered), store the
key with `npx firebase apphosting:secrets:set firebase-web-api-key --project lifelinkkh`, and set
`SUPPORT_EMAIL` in that file. Revisit this at the 500-user decision, not before.

## Part E — End-to-end on the real project

Two real Android phones, both with the **release APK** from `bash scripts/build-release-apk.sh`,
installed from the `/km/download` page the way a user would.

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

> **Google sign-in on the release APK.** The release APK is signed with the upload keystore, not
> the debug key, so its **SHA-1 and SHA-256 must be in Firebase** (Project settings → Android app),
> then `google-services.json` downloaded again — deploy-runbook Step 4. Without it, Google sign-in
> fails with a generic error on every installed phone, while `flutter run` on your laptop works
> fine. (If LifeLink later moves to the Play Store, Play's own app-signing SHA-1 must be added too.)

## Part F — Launch readiness (before anyone outside the team uses it)

Everything in Part A–E makes the app *work* for real. This part makes it *fit* for real, and these
items do not come from code.

**Before inviting users (sideloaded APK, until 500 users):**
- [ ] **Privacy policy** — written: `https://<portal>/km/privacy` (English at `/en/privacy`), text
  in `frontend/src/messages/{en,km}.json` under `privacy`, each claim checked against the rules and
  Functions. Before listing:
  - [ ] a native Khmer speaker reads the Khmer version;
  - [ ] someone who knows Cambodian law reads it, if the partner hospital or NBTC can arrange it —
    it was written against the code, not by a lawyer;
  - [ ] confirm the **18+** age line is what you want (it is a product decision the policy states);
  - [ ] publish its URL with `npm run release -- … --privacy-url https://<portal>/km/privacy`; the
    app's Me tab links to whatever `config/app` says, and hides the link until it is set.
- [ ] **Account deletion (DEC-016)** — built: **Me → Delete account** in the app (the
  `deleteAccount` callable, fresh sign-in required), and the web link
  `https://<portal>/km/delete-account`. Before inviting users:
  - [ ] set `SUPPORT_EMAIL` on Vercel (Part D) to an address someone reads — without it the page
    says the address is not set up;
  - [ ] for each email that arrives: find the uid (Authentication → search the email), make sure
    the email really is that Google account, then
    `npm run delete-account -- --uid <uid> --project lifelinkkh` from `firebase/` and reply;
  - [ ] try it once on a test account on the real project, and check that the account's rows are
    gone or anonymised.
- [ ] *(Later, only when moving to the Play Store)* **Play Console → Data safety** form, consistent
  with the privacy policy's "What we collect" list: name, email, approximate and precise location (optional), health info (blood type, donation
  date), phone number (on requests), app interactions; encrypted in transit; users can request
  deletion; no data shared for advertising.

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
- [ ] A second admin account for the day `nemsothea` is unavailable: run `seed:admin` again with
  another `PORTAL_ADMIN_USERNAME`. (`soborey` exists on `lifelinkkh` but is **disabled** — its
  first password was exposed on 2026-09-28. Re-enable it only after `--reset-passwords`.)
- [ ] Watch the billing page and the Functions logs weekly for the first month. At **500 users**,
  make the paid-or-not decision with `npm run metrics -- --project lifelinkkh` and the month's
  usage in hand.
- [ ] The portal shows "Could not load" to an admin whose access was revoked. Make it send them
  to sign in instead (known gap).
- [ ] iOS: out of scope (DEC-006). An iOS release would need an Apple Developer account and an
  APNs key uploaded to Firebase, or no iPhone ever receives a push.

---

## Related

- [`deploy-runbook.md`](deploy-runbook.md) — Path A: the sideloaded APK (now). Path B: Play Store (later).
- [`local-development.md`](local-development.md) — the emulator stack.
- [`firebase/README.md`](../../firebase/README.md) — every Firebase command.
- ADR 0009, DEC-012 (demo first), DEC-014 (admin-only portal), DEC-015 (review before alert).
