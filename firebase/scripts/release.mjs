// Publish a new APK version to config/app, the document the app reads at start to decide whether
// to say "a new version is available" or "update required". The APK is sideloaded (no Play Store
// until 500 users), so this is the only way an installed app learns there is something newer.
//
//   npm run release -- --version-code 3 --version-name 1.0.2 \
//       --download-url https://<portal>/km/download --privacy-url https://<portal>/km/privacy
//   npm run release -- --version-code 3 --version-name 1.0.2 --min 3 ...   # force everyone to update
//   … --project lifelinkkh                                                  # the REAL project
//
// Run it AFTER the APK is uploaded: the moment this is written, every installed app points its
// users at the download link. `--min` is for a build that must not keep running (a broken release,
// a rules change the old app cannot follow); leave it out and the old minimum is kept.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

const arg = (name) => {
  const i = process.argv.indexOf(name);
  return i > -1 ? process.argv[i + 1] : undefined;
};
const real = arg('--project') !== undefined;
const projectId = arg('--project') ?? 'lifelinkkh';
const versionCode = Number(arg('--version-code'));
const versionName = arg('--version-name');
const minArg = arg('--min');
const downloadUrl = arg('--download-url');
const privacyUrl = arg('--privacy-url');

const fail = (message) => {
  console.error(message);
  process.exit(2);
};
if (!Number.isInteger(versionCode) || versionCode < 1) fail('--version-code is the +N of pubspec version, a whole number ≥ 1');
if (!versionName) fail('--version-name is the visible version, e.g. 1.0.2');
for (const [name, url] of [['--download-url', downloadUrl], ['--privacy-url', privacyUrl]]) {
  if (url !== undefined && !/^https:\/\//.test(url)) fail(`${name} must be an https:// URL`);
}
if (!real) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
if (real && process.env.FIRESTORE_EMULATOR_HOST) fail(`FIRESTORE_EMULATOR_HOST is set, so "${projectId}" would silently mean the emulator. Unset it.`);

initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
const ref = getFirestore().doc('config/app');
const current = (await ref.get()).data() ?? {};

if (current.latestVersionCode && versionCode < current.latestVersionCode) {
  fail(`latestVersionCode is already ${current.latestVersionCode}; refusing to go back to ${versionCode}.`);
}
const minVersionCode = minArg === undefined ? (current.minVersionCode ?? 1) : Number(minArg);
if (!Number.isInteger(minVersionCode) || minVersionCode < 1 || minVersionCode > versionCode) {
  fail(`--min must be a whole number between 1 and ${versionCode}`);
}

await ref.set({
  latestVersionCode: versionCode,
  latestVersionName: versionName,
  minVersionCode,
  ...(downloadUrl ? { downloadUrl } : {}),
  ...(privacyUrl ? { privacyUrl } : {}),
  updatedAt: FieldValue.serverTimestamp(),
}, { merge: true });

console.log(`${real ? 'REAL PROJECT' : 'emulator'} ${projectId}: latest ${versionName} (${versionCode}), minimum ${minVersionCode}`);
process.exit(0);
