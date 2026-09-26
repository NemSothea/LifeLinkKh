// Checks the seed landed on the emulator: counts, and that every hospital's district exists
// — the foreign key V4 had, which Firestore does not enforce.
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8081';
initializeApp({ projectId: 'demo-lifelink' });
const db = getFirestore();

const districts = new Set((await db.collection('districts').get()).docs.map((d) => d.id));
const hospitals = (await db.collection('hospitals').get()).docs;
const orphans = hospitals.filter((h) => !districts.has(h.get('districtCode')));

console.log(`districts ${districts.size}, hospitals ${hospitals.length}, orphans ${orphans.length}`);
if (districts.size !== 14 || hospitals.length !== 5 || orphans.length) process.exit(1);
