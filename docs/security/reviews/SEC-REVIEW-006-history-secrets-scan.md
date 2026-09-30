---
id: SEC-REVIEW-006
feature: community-launch Phase 1 (public repo readiness)
date: 2026-09-30
verdict: pass-with-conditions
---
## Scope reviewed
Full git history of `NemSothea/LifeLinkKh`, all branches: 241 commits, about 6.6 MB. Scanned with
`gitleaks git . --log-opts="--all" --redact`, gitleaks 8.30.1. The repo is already public, so
anything found here would already be exposed.

## Findings
Eleven hits. None is a live secret.

| # | Rule | File | Commit | Assessment |
|---|---|---|---|---|
| 1–2 | gcp-api-key | `mobile/android/app/google-services.json` | 8890756, 64e4835 | Firebase **client** API key, committed on purpose (`.gitignore` note). It identifies the project and grants nothing by itself. Firestore rules and Auth enforce access. **Condition C1.** |
| 3–4 | generic-api-key | `frontend/src/server/common-passwords.json` | 1f0f501 | The common-password denylist. False positive. |
| 5–9 | generic-api-key | `mobile/ios/Podfile.lock` | a57b83c | CocoaPods checksums. False positive. |
| 10–11 | generic-api-key | `backend/.../JwtServiceTest.java`, `backend/src/test/resources/application-test.yml` | 55003c6 | Test-only JWT secret for `test-project`, in the Spring Boot backend that ADR 0009 removed. It was never used by a deployed service. No action. |

The service-account JSON, `key.properties`, `*.jks` and `.env*` files do not appear anywhere in the history.

All 11 fingerprints are listed in `/.gitleaksignore`, so later scans show only new findings.
A re-scan after adding the file reports `no leaks found`.

## Verdict & conditions
**Pass with conditions.** The repo may be advertised publicly.

- **C1 (human step, Google Cloud console → APIs & Services → Credentials):** confirm that the
  Android key in `google-services.json` is restricted to the Android app (package
  `com.kosigndemo.lifelinkkh` + release SHA-1) and to the Firebase APIs it needs. Do the same for
  the iOS key (bundle ID) and the web key (Identity Toolkit only, as `.env.example` says).
- **C2:** add a CI step that runs gitleaks on every PR, so new secrets are caught before merge
  (Tech Lead owns `.github/workflows/`; to be proposed separately).
