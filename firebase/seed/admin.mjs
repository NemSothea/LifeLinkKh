// The portal's admin account — soborey, from V13 — as a Firebase Auth user with its ADMIN claim
// and admins/{uid} record (ADR 0009, phase 5). v1 has no hospital staff, and no page grants
// access: an admin exists because this ran. Same three rules PortalPasswordBootstrap followed:
//
//   - An unset password sets nothing. No default, no generated password printed anywhere.
//   - A password shorter than 12 characters is refused.
//   - An account that already exists keeps its password (it may have been changed in the portal)
//     unless --reset-passwords is passed. Its claim and record are always put right.
//
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin                       # emulator, demo-lifelink
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin:app                   # emulator, lifelinkkh
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin -- --project lifelinkkh   # REAL project
//   PORTAL_ADMIN_USERNAME=nemsothea PORTAL_ADMIN_NAME='Nem Sothea' PORTAL_ADMIN_PASSWORD=… \
//     npm run seed:admin -- --project lifelinkkh                        # another admin
//
// To end an admin's access: delete admins/{uid} (the rules refuse them on the next read) and
// disable the user in the Firebase console. The password is never logged.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { portalEmail } from '../functions/src/portal-accounts.js';

const projectFlag = process.argv.indexOf('--project');
const projectId = projectFlag > -1 ? process.argv[projectFlag + 1] : 'demo-lifelink';
const real = !projectId.startsWith('demo-') && !process.argv.includes('--emulator');
const resetPasswords = process.argv.includes('--reset-passwords');

if (!real) {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
}
if (real && (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST)) {
  console.error(`An emulator host is set, so "${projectId}" would silently mean the emulator. Unset it.`);
  process.exit(1);
}

// PORTAL_ADMIN_USERNAME / PORTAL_ADMIN_NAME pick another admin; soborey stays the default.
const username = process.env.PORTAL_ADMIN_USERNAME ?? 'soborey';
if (!/^[a-z0-9][a-z0-9._-]{2,31}$/.test(username)) {
  console.error(`PORTAL_ADMIN_USERNAME "${username}" must be 3-32 lowercase letters, digits, ".", "_" or "-".`);
  process.exit(1);
}
const ADMIN = {
  username,
  displayName: process.env.PORTAL_ADMIN_NAME ?? username.charAt(0).toUpperCase() + username.slice(1),
};
const MIN_LENGTH = 12;

const password = process.env.PORTAL_ADMIN_PASSWORD;
if (!password) {
  console.warn(`PORTAL_ADMIN_PASSWORD is not set, so ${ADMIN.username} was not created.`);
  process.exit(0);
}
if (password.length < MIN_LENGTH) {
  console.error(`PORTAL_ADMIN_PASSWORD is shorter than ${MIN_LENGTH} characters and was REFUSED.`);
  process.exit(1);
}

initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
const db = getFirestore();
const auth = getAuth();

const email = portalEmail(ADMIN.username);
let user = await auth.getUserByEmail(email).catch((e) => {
  if (e.code === 'auth/user-not-found') return null;
  throw e;
});
if (!user) {
  user = await auth.createUser({ email, password, displayName: ADMIN.displayName });
} else {
  await auth.updateUser(user.uid, {
    displayName: ADMIN.displayName,
    disabled: false,
    ...(resetPasswords ? { password } : {}),
  });
}
await auth.setCustomUserClaims(user.uid, { role: 'ADMIN' });
await db.doc(`admins/${user.uid}`).set({
  displayName: ADMIN.displayName,
  username: ADMIN.username,
  updatedAt: FieldValue.serverTimestamp(),
}, { merge: true });

console.log(`${real ? 'REAL PROJECT' : 'emulator'} ${projectId}: admin ${ADMIN.username} in place`);
