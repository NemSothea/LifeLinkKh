# Contributing to LifeLink KH

**ភាសាខ្មែរ: [CONTRIBUTING.km.md](CONTRIBUTING.km.md)**

Thank you for helping. LifeLink KH connects blood donors with patients in Cambodia, and every fix,
translation or test helps. You don't need to be an expert: typo fixes and Khmer translations are
real contributions.

Before you start, read the [Code of Conduct](CODE_OF_CONDUCT.md). Report security problems through
[SECURITY.md](SECURITY.md), **never** in a public issue.

## Ways to help

| You are… | Start with |
|---|---|
| A Khmer speaker | Issues labelled [`translation-km`](https://github.com/NemSothea/LifeLinkKh/labels/translation-km): check that strings read naturally |
| New to open source | Issues labelled [`good first issue`](https://github.com/NemSothea/LifeLinkKh/labels/good%20first%20issue) |
| A Flutter developer | [`mobile`](https://github.com/NemSothea/LifeLinkKh/labels/mobile) |
| A web / Next.js developer | [`web`](https://github.com/NemSothea/LifeLinkKh/labels/web) |
| A doctor, nurse or blood-bank worker | Open a feature or bug issue if anything the app says about donation is wrong |
| A user | A bug report with steps and a screenshot, with no personal data in it |

## Run it locally (no team credentials needed)

Everything runs on the **Firebase emulators**. You never need access to the real `lifelinkkh`
project, a service-account key or a signing keystore.

**You need:** JDK 21, Node 22 (Node 20 fails with `EBADENGINE`), and Flutter 3.44.6 if you work on
the app.

```bash
git clone https://github.com/NemSothea/LifeLinkKh.git && cd LifeLinkKh

# Terminal 1: the emulators (Firestore :8081, Auth :9099, UI :4000)
cd firebase && npm ci && npm run emulators:app

# Terminal 2: seed data, then the portal
cd firebase
npm run seed:app                                             # districts + hospitals
PORTAL_ADMIN_PASSWORD='choose-12-or-more' npm run seed:admin:app  # admin "soborey", your password
npm run seed:showcase                                        # 24 demo donors, 15 requests
cd ../frontend && npm ci
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run dev
```

Open <http://localhost:3000> for the portal and <http://localhost:4000> for the emulator UI.

**How long it takes:** measured on a clean clone on 2026-09-30 (macOS, JDK 21 and Node already
installed, emulator JARs already cached), from `git clone` to the public board rendering seeded
requests: **about 1.5 minutes of machine time**. Clone plus both `npm ci` runs took 41 s, the
emulators 6 s, the seeds 12 s, and the portal's first page 5 s. A first-ever emulator start also
downloads the Firestore emulator (tens of MB). With reading time, plan on about 15 minutes.

If ports 8081, 9099 or 4000 are already taken (another emulator running), stop that one first or
change the ports in `firebase/firebase.json` locally, without committing the change.

The app, with the portal running:

```bash
cd mobile && flutter run \
  --dart-define=FIRESTORE_EMULATOR=10.0.2.2:8081 \
  --dart-define=PORTAL_URL=http://10.0.2.2:3000     # Android emulator addresses
```

The emulators send no push notifications (FCM has no emulator) and keep nothing after a restart.
More detail, including every failure the team has hit: [`docs/tech-lead/local-development.md`](docs/tech-lead/local-development.md).

## Making a change

1. **Talk first for anything bigger than a small fix** (sizes and paths in [`GOVERNANCE.md`](GOVERNANCE.md)). Comment on the issue, or open one. This
   project records its decisions (`docs/decisions.md`, `docs/tech-lead/adr/`); a change that
   reverses one needs a discussion before code.
2. Fork, then branch from the default branch: `fix/short-name`, `feat/short-name`, `docs/short-name`.
3. Keep the change small and focused. One PR, one purpose.
4. **Every user-facing string needs Khmer and English.**
   - Portal: `frontend/src/messages/km.json` and `en.json`.
   - App: `mobile/lib/l10n/app_km.arb` and `app_en.arb`.

   If you can't write the Khmer, add the English, say so in the PR, and a Khmer speaker will help.
5. Run the checks before you push:
   ```bash
   bash scripts/verify-all.sh      # every client, the same script CI runs
   ```
   A skipped test is not a pass. The rules and functions emulator tests need Java 21.
6. Commit messages follow the existing history, [Conventional Commits](https://www.conventionalcommits.org)
   with a scope:
   ```
   fix(mobile): alerts on closed requests leave Home
   feat(portal): share image for link previews
   docs: README screenshots from real phones
   ```
   Types: `feat` `fix` `docs` `test` `refactor` `style` `build` `ci` `chore`. Scopes include
   `mobile` `portal` `firebase` `auth` `security` `scripts` `po`.
7. Open a pull request and fill in the template.

## Rules that protect donors

- **No real personal data anywhere**: not in code, tests, screenshots, logs or issues. Use the
  seed data (`npm run seed:showcase`).
- **Never commit secrets:** `.env*`, service-account JSON, `key.properties`, `*.jks`. `.gitignore`
  covers them, so don't force-add them.
- A change to `firebase/firestore.rules` needs a matching test in `firebase/rules-tests/`. A rule
  without a test counts as absent.
- Medical content follows Cambodian practice and the National Blood Transfusion Center
  (DEC-019). Don't add medical claims without a source.

## Who reviews what

Each area has an owner, listed in [`docs/team.md`](docs/team.md) and [`GOVERNANCE.md`](GOVERNANCE.md).
[`.github/CODEOWNERS`](.github/CODEOWNERS) requests a reviewer on your PR automatically.

| Area | Paths |
|---|---|
| Mobile app | `mobile/`, `docs/mobile/` |
| Web portal | `frontend/` |
| Firebase rules, seeds | `firebase/`, `docs/fullstack/` |
| Product docs | `docs/po/` |
| Tests and QA | `docs/qa/` |
| CI, architecture, security | `.github/`, `docs/tech-lead/`, `docs/security/` |

Outside contributors may send a PR to any area; the owner reviews it. We aim to reply within 7 days.

## Where to ask

- [GitHub Discussions](https://github.com/NemSothea/LifeLinkKh/discussions) for questions, ideas and proposals.
- Telegram: `[TELEGRAM_LINK]` · Facebook: `[FB_PAGE]`.
- Bugs and features always go in GitHub issues, so they don't get lost in chat.

## License

By contributing, you agree that your code is licensed under [Apache-2.0](LICENSE) and your
documentation or images under [CC BY 4.0](LICENSE-docs), the same terms as the rest of the project
(DEC-020). There is no CLA to sign.
