// DEC-016: delete one account for a person who asked through the web link
// (/{locale}/delete-account) because they can no longer use the app. The same code the app's
// "Delete account" runs, without the recent-sign-in check — the operator verified the person.
//
//   npm run delete-account -- --uid <uid>                        # the emulator, project lifelinkkh
//   npm run delete-account -- --uid <uid> --project lifelinkkh   # REAL (GOOGLE_APPLICATION_CREDENTIALS)
//
// Find the uid in the Firebase console (Authentication, search by email). Irreversible.
//
// The handler lives in the portal since ADR 0010, and so does the firebase-admin it uses:
// `admin-sdk.js` re-exports that copy, because a FieldValue from a second copy is not
// serialisable by the first.
import { applicationDefault, getAuth, getFirestore, initializeApp } from '../../frontend/src/server/admin-sdk.js';
import { deleteAccountData } from '../../frontend/src/server/delete-account.js';

const arg = (name) => {
  const i = process.argv.indexOf(name);
  return i > -1 ? process.argv[i + 1] : undefined;
};
const uid = arg('--uid');
const real = arg('--project') !== undefined;
const projectId = arg('--project') ?? 'lifelinkkh';
if (!uid) {
  console.error('usage: npm run delete-account -- --uid <uid> [--project lifelinkkh]');
  process.exit(2);
}
if (!real) {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
}
if (real && (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST)) {
  console.error(`An emulator host is set, so "${projectId}" would silently mean the emulator. Unset it.`);
  process.exit(1);
}
initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
const auth = getAuth();

const user = await auth.getUser(uid).catch(() => null);
const role = user?.customClaims?.role;
if (role === 'ADMIN') {
  console.error('That is an admin account. Delete admins/{uid} and disable the user in the console instead (DEC-014).');
  process.exit(1);
}
const result = await deleteAccountData({ db: getFirestore(), auth, uid });
console.log(`${real ? 'REAL PROJECT' : 'emulator'}: deleted ${uid}`, result);
process.exit(0);
