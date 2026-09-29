// The portal's admin account — soborey, from V13 — as a Firebase Auth user with its ADMIN claim
// and admins/{uid} record (ADR 0009, phase 5). v1 has no hospital staff, and no page grants
// access: an admin exists because this ran. Same three rules PortalPasswordBootstrap followed:
//
//   - An unset password sets nothing. No default, no generated password printed anywhere.
//   - A password shorter than 12 characters, or one of the 3000 most common, is refused.
//   - Against the real project the username must be given; soborey is the emulator default only.
//   - An account that already exists keeps its password (it may have been changed in the portal)
//     unless --reset-passwords is passed. Its claim and record are always put right.
//
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin                       # emulator, demo-lifelink
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin:app                   # emulator, lifelinkkh
//   PORTAL_ADMIN_PASSWORD=… npm run seed:admin -- --project lifelinkkh   # REAL project
//   PORTAL_ADMIN_USERNAME=nemsothea PORTAL_ADMIN_NAME='Nem Sothea' PORTAL_ADMIN_PASSWORD=… \
//     npm run seed:admin -- --project lifelinkkh                        # another admin
//   PORTAL_ADMIN_GOOGLE_EMAIL=someone@gmail.com npm run seed:admin -- --project lifelinkkh
//                                                                      # a Google admin, no password
//
// To end an admin's access: delete admins/{uid} (the rules refuse them on the next read) and
// disable the user in the Firebase console. The password is never logged.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { portalEmail } from '../../frontend/src/server/portal-accounts.js';
import COMMON_PASSWORDS from '../../frontend/src/server/common-passwords.json' with { type: 'json' };

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

// PORTAL_ADMIN_GOOGLE_EMAIL: make an existing Google account an admin, for "Sign in with Google"
// on the portal. No password is involved. The account must have signed in with Google once
// already (the portal or the app), which is what creates its Firebase user; this refuses an
// address that has no Google sign-in on it, so a typo cannot hand the claim to someone else's
// password account.
const googleEmail = process.env.PORTAL_ADMIN_GOOGLE_EMAIL?.trim().toLowerCase();
if (googleEmail) {
  initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
  const auth = getAuth();
  const user = await auth.getUserByEmail(googleEmail).catch((e) => {
    if (e.code === 'auth/user-not-found') return null;
    throw e;
  });
  if (!user) {
    console.error(`${googleEmail} has no Firebase user yet. Sign in with Google once (the portal says "not an admin"), then run this again.`);
    process.exit(1);
  }
  if (!user.providerData.some((p) => p.providerId === 'google.com')) {
    console.error(`${googleEmail} exists but has never signed in with Google. REFUSED.`);
    process.exit(1);
  }
  const displayName = process.env.PORTAL_ADMIN_NAME ?? user.displayName ?? googleEmail;
  await auth.setCustomUserClaims(user.uid, { ...user.customClaims, role: 'ADMIN' });
  await getFirestore().doc(`admins/${user.uid}`).set({
    displayName,
    username: googleEmail,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  console.log(`${real ? 'REAL PROJECT' : 'emulator'} ${projectId}: Google admin ${googleEmail} in place (sign out and in again to pick up the claim)`);
  process.exit(0);
}

// PORTAL_ADMIN_USERNAME / PORTAL_ADMIN_NAME pick another admin; soborey stays the default on
// the emulators. Against the real project the username must be given (SEC-REVIEW-003 F-16):
// a default that is in this public repo is the first name anyone would try.
if (real && !process.env.PORTAL_ADMIN_USERNAME) {
  console.error('PORTAL_ADMIN_USERNAME is required against the real project; there is no default there.');
  process.exit(1);
}
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
// The portal's change-password page refuses these too (SEC-REVIEW-003 F-14).
if (COMMON_PASSWORDS.includes(password.toLowerCase())) {
  console.error('PORTAL_ADMIN_PASSWORD is one of the most common passwords and was REFUSED.');
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
