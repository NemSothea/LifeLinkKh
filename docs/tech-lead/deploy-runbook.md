# Deploy runbook — signed release to Play Store internal testing

**Owner:** Tech Lead. This is the second half of the deploy runbook M7 needs —
[`local-development.md`](local-development.md) is the first half (running the stack on a laptop).
This half covers turning a working local build into a **signed AAB on Play Store's internal
testing track**, which is what M7 (root `CLAUDE.md` §4) actually requires. A sideloaded APK does
not satisfy it — testers must install through the Play Store app itself.

Closes the gap named in `docs/risks.md` ("no deploy runbook exists") and `docs/scope.md`
("Deploy runbook — M7 signed-AAB release has no documented promotion path").

---

## Prerequisites

- **Google Play Console account, $25 one-time.** `docs/scope.md` flagged this as external lead
  time back in Week 3 — identity verification can take days. Confirm it is actually verified
  before starting Step 6, not the night before a defense.
- `keytool`, ships with JDK 21 (already required by `local-development.md`).
- A machine that already passes `local-development.md` end to end — a signed build on top of a
  broken local one just hides two problems as one.

---

## Step 1 — generate the upload keystore

```bash
keytool -genkeypair -v -keystore ~/lifelinkkh-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias lifelinkkh-upload
```

Store it **outside the repo** — home directory or the team password manager as a file
attachment, never under `mobile/`. `.gitignore` blocks `*.jks`/`*.keystore` anyway, but the
control that matters is never creating it inside the tree in the first place.

Enable **Play App Signing** when you create the app in Play Console (it is the default now, not
opt-in). Google then holds the real signing key and this "upload key" only authenticates you to
the Console. That matters because it changes what losing the keystore later means: with Play App
Signing on, it is recoverable through Google's identity-verification reset; with it off, losing
the keystore after the first upload means the app can never be updated again under the same
listing.

Record the keystore password, key alias, and key password in the team password manager. Not in
this file, not in chat, not in a commit — same rule `local-development.md` Step 2 applies to
`POSTGRES_PASSWORD`.

---

## Step 2 — `key.properties`

```bash
cp mobile/android/key.properties.example mobile/android/key.properties
```

Fill in the four values from Step 1. `mobile/android/key.properties` is gitignored
(`.gitignore`); the `.example` template is committed on purpose so the shape is documented
without the secrets.

```
storePassword=...
keyPassword=...
keyAlias=lifelinkkh-upload
storeFile=/absolute/path/to/lifelinkkh-upload.jks
```

`storeFile` is an absolute path — this file is never shared between machines, so there is no
portability to preserve.

---

## Step 3 — signing config (already wired)

`mobile/android/app/build.gradle.kts` reads `key.properties` if present and signs `release`
builds with it; if the file is absent, `release` falls back to the debug key so
`flutter run --release` still works for anyone who has not fetched the upload key. This mirrors
the risk `local-development.md` calls out for `google-services.json`, but resolves the opposite
way on purpose: a *missing* release signature should not block everyday dev builds the way a
missing Firebase config correctly blocks Google Sign-In, because most local/CI runs never touch
the Play Store. Nothing to do here unless the Gradle file itself needs to change.

---

## Step 4 — register the release SHA-1 with Firebase

```bash
keytool -list -v -keystore ~/lifelinkkh-upload.jks -alias lifelinkkh-upload
```

Add the SHA-1 (and SHA-256) it prints to the Android app's config in the Firebase console —
**in addition to**, not instead of, the debug SHA-1 already there (`local-development.md` 5a).
Re-download `google-services.json` afterward and replace the committed copy at
`mobile/android/app/google-services.json` — Firebase folds all registered fingerprints into that
one file, so the copy taken before this step is stale.

Skip this and Google Sign-In fails silently on the signed release build specifically — same
failure mode as an unregistered debug SHA-1, just gated to the build type testers actually run.

---

## Step 5 — `API_BASE_URL` for real devices: tunnel the local backend (DEC-007)

Every `flutter run`/`flutter build` requires `--dart-define=API_BASE_URL`, and it is baked into
the binary at compile time — it cannot be changed after the AAB is built. `local-development.md`
and `demo-runbook.md` both use addresses that only work for the person building
(`10.0.2.2` = emulator-only alias, or a LAN IP) or a local backend. Internal testers install a
Play-Store binary on their own devices, off the emulator and (routinely) off the same LAN.

**Decided 2026-08-29, [DEC-007](../decisions.md#dec-007--m7-internal-testing-backend-reached-via-tunnel-not-a-hosted-deploy):**
for M7, testers reach the backend through a tunnel (`ngrok` or `cloudflared`) pointed at the
backend running on a team laptop — not a hosted deploy. Read DEC-007 for the full reasoning; the
practical consequences for this runbook:

1. Bring the local stack up (`local-development.md`), then start a tunnel against the backend
   port: `ngrok http 8080` (or `cloudflared tunnel --url http://localhost:8080`).
2. Use the `https://...` URL the tunnel prints as `API_BASE_URL` in Step 6 — **with `/api`**,
   matching the context path `local-development.md` documents (e.g.
   `https://<random>.ngrok-free.app/api`).
3. The backend + tunnel must stay running for the entire internal-testing window. A free-tier
   `ngrok` URL changes every time it restarts — restarting it after Step 6 has already run means
   rebuilding and re-uploading the AAB, since the old URL is frozen inside it.
4. **Not durable past M7.** Revisit (most likely as a real hosted deploy, DEC-007's rejected
   option 2) before any real donor outside the team uses the app.

---

## Step 6 — build the signed AAB

```bash
cd mobile
flutter build appbundle --release --dart-define=API_BASE_URL=<url decided in Step 5>
```

Output: `mobile/build/app/outputs/bundle/release/app-release.aab`.

**Bump the version before every upload.** `pubspec.yaml` is currently `version: 1.0.0+1` — Play
Console rejects a re-upload that reuses a previously-used `versionCode` (the `+1` suffix), even
to internal testing.

---

## Step 7 — Play Console: internal testing track

1. Create the app if it does not exist yet. Play Console will not let you publish to internal
   testing without the store-listing minimums: app icon, short and full description, a privacy
   policy URL, the content-rating questionnaire, and the Data Safety form.
2. **Data Safety form — answer it honestly, it is not busywork here.** This project already
   treats blood type as health data (ADR 0003) and collects district-level location; Play's form
   has a specific "health info" category. Understating it is the kind of thing a course reviewer
   or a real user could catch later.
3. **Testing → Internal testing → Create new release**, upload the AAB from Step 6, add release
   notes, save.
4. Add testers by Google account email under that track's **Testers** tab — the team's five
   accounts at minimum.
5. Roll out. Testers accept via the opt-in URL Play Console generates and install through the
   Play Store app on their device — that install path is what "published to Play Store internal
   testing" in M7 means, not a shared AAB file.

---

## Step 8 (later, not blocking M7) — wire the signed build into CI

`.github/workflows/ci.yml` currently ends in a comment noting this needs the upload keystore in
repository secrets plus this runbook. When it is time:

- Base64-encode the `.jks` and store it as a GitHub Actions secret; decode it to a file in a
  step. Store the four `key.properties` values as secrets too.
- Add a `mobile-release` job running `flutter build appbundle --release` with the decoded
  keystore and the chosen `API_BASE_URL`.
- Gate it to a tag or manual `workflow_dispatch`, not every push to `main` — an AAB per commit
  burns Play Console's upload attention for no benefit and this project has no auto-promotion
  pipeline to feed anyway.

Do this only after Step 6-7's manual path has actually produced one accepted upload. Automating
a path nobody has proven yet just moves the same open questions (Step 5's URL, first-time Data
Safety answers) into YAML instead of answering them.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Release build still installs over/as the debug-signed app, or Play Console rejects the upload as unsigned | `key.properties` missing or `storeFile` path wrong | Confirm `mobile/android/key.properties` exists and `storeFile` is an absolute, existing path |
| Google Sign-In fails silently on the installed release build only | Release SHA-1 (Step 4) not registered, or `google-services.json` not re-downloaded after adding it | Step 4, then rebuild — a stale `google-services.json` is the most common miss here |
| Play Console: "You need to use a different version code" | `pubspec.yaml`'s `+N` reused | Bump it (Step 6) |
| Testers report the app can't reach the server at all | `API_BASE_URL` baked in at build time pointed at a tunnel/IP that is no longer live | Restart the tunnel/backend, or if the URL changed, rebuild and re-upload — cannot be patched without a new AAB |
| `keytool -genkeypair` overwrote/reused a keystore you didn't mean to touch | Ran Step 1 against an existing filename | `keytool` does not warn before overwriting; always pick a new filename or check `ls` first |

---

## Related

- [`local-development.md`](local-development.md) — first half: running the stack locally
- [`docs/demo-runbook.md`](../demo-runbook.md) — the golden path for a live demo, not a Play Store release
- [`docs/scope.md`](../scope.md) — why `FR-SECURITY-001` (account/data deletion) stays deferred only
  while the pilot is team-only, which is exactly the assumption Step 5's Option 1 also leans on
- `mobile/android/app/build.gradle.kts`, `mobile/android/key.properties.example` — owned by Tech Lead
