Put the Firebase service-account JSON here.

The whole directory is gitignored (root .gitignore). Only this file is tracked,
so the path exists in a fresh clone and nobody has to guess where the key goes.

  secrets/firebase-service-account.json

Then set GOOGLE_APPLICATION_CREDENTIALS in .env to its ABSOLUTE path and bring
the stack up with the firebase overlay — see docs/tech-lead/local-development.md.
