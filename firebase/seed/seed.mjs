// Writes the reference data — the 14 districts (V3, DEC-005) and 5 hospitals (V7) — into
// Firestore. ADR 0009. Idempotent: every document is written with set(), so a re-run leaves
// the same state, and ids are the Postgres ones so a hospital keeps its identity across
// the move.
//
//   npm run seed                      # the local emulator, project demo-lifelink (tests)
//   npm run seed:app                  # the local emulator, project lifelinkkh — what the app
//                                     # reads when run with FIRESTORE_EMULATOR (README)
//   npm run seed -- --project lifelinkkh
//                                     # the REAL project; needs GOOGLE_APPLICATION_CREDENTIALS
//                                     # pointing at a service-account key in secrets/
//
// Never touches donors, requests, matches or donations.
import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { geohashForLocation } from 'geofire-common';

const projectFlag = process.argv.indexOf('--project');
const projectId = projectFlag > -1 ? process.argv[projectFlag + 1] : 'demo-lifelink';
const real = !projectId.startsWith('demo-') && !process.argv.includes('--emulator');

if (!real) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
if (real && process.env.FIRESTORE_EMULATOR_HOST) {
  console.error(`FIRESTORE_EMULATOR_HOST is set, so "${projectId}" would silently mean the emulator. Unset it.`);
  process.exit(1);
}

initializeApp(real ? { projectId, credential: applicationDefault() } : { projectId });
const db = getFirestore();

const { districts, hospitals } = JSON.parse(
  readFileSync(new URL('./reference-data.json', import.meta.url), 'utf8'),
);

const batch = db.batch();
for (const d of districts) {
  batch.set(db.doc(`districts/${d.code}`), { nameKm: d.nameKm, nameEn: d.nameEn });
}
for (const h of hospitals) {
  batch.set(db.doc(`hospitals/${h.id}`), {
    name: h.name,
    address: h.address,
    contactPhone: h.contactPhone,
    lat: h.lat,
    lng: h.lng,
    geohash: geohashForLocation([h.lat, h.lng]),
    districtCode: h.districtCode,
  });
}
await batch.commit();

console.log(`${real ? 'REAL PROJECT' : 'emulator'} ${projectId}: ${districts.length} districts, ${hospitals.length} hospitals`);
