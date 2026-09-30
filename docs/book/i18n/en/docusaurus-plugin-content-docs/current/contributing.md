---
title: Contributing
sidebar_position: 6
description: How to help LifeLink KH — Khmer translation, code, testing and reporting — and how to run it locally in about 15 minutes.
---

# Contributing

LifeLink KH is an open community project. You don't need to be an expert. Typo fixes and
Khmer translations are real contributions.

| You are… | Start with |
|---|---|
| A Khmer speaker | [`translation-km` issues](https://github.com/NemSothea/LifeLinkKh/labels/translation-km) and the [translation guide](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/docs/community/translating.md) |
| New to open source | [`good first issue`](https://github.com/NemSothea/LifeLinkKh/labels/good%20first%20issue) |
| A Flutter or web developer | [`mobile`](https://github.com/NemSothea/LifeLinkKh/labels/mobile), [`web`](https://github.com/NemSothea/LifeLinkKh/labels/web) |
| A doctor, nurse or blood-bank worker | Tell us if anything the app says about donation is wrong: open an issue |
| A user | A bug report with steps and a screenshot, with no personal data in it |

## Run it locally in about 15 minutes

Everything runs on the **Firebase emulators**, so you need no team credentials. You need JDK 21 and
Node 22 (and Flutter 3.44.6 for the app).

```bash
git clone https://github.com/NemSothea/LifeLinkKh.git && cd LifeLinkKh
cd firebase && npm ci && npm run emulators:app          # terminal 1
```

```bash
cd firebase                                              # terminal 2
npm run seed:app
PORTAL_ADMIN_PASSWORD='choose-12-or-more' npm run seed:admin:app
npm run seed:showcase
cd ../frontend && npm ci
FIRESTORE_EMULATOR_HOST=127.0.0.1:8081 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm run dev
```

Open [http://localhost:3000](http://localhost:3000). On a clean clone this took about 1.5 minutes of machine time.

## The rules

- Every user-facing string ships in **Khmer and English**.
- **No real personal data** anywhere: code, tests, screenshots, issues.
- A change to the Firestore rules needs a test.
- Medical content follows Cambodian practice and the NBTC.
- Run `bash scripts/verify-all.sh` before you push.

The full guide: [CONTRIBUTING.md](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/CONTRIBUTING.md) ·
[ភាសាខ្មែរ](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/CONTRIBUTING.km.md) ·
how decisions are made: [GOVERNANCE.md](https://github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/GOVERNANCE.md).

## Improve this book

Every page has an **Edit this page** link at the bottom. The Khmer pages are in `docs/book/docs/`,
the English ones in `docs/book/i18n/en/docusaurus-plugin-content-docs/current/`. Preview locally:

```bash
cd docs/book && npm ci && npm start          # Khmer
npm run start:en                             # English
```
