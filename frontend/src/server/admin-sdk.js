// The one firebase-admin the handlers use, re-exported for the scripts under `firebase/` that
// call them directly (`seed/demo.mjs`, `scripts/delete-account.mjs`). Node resolves a package
// from the importing file's own `node_modules`, so a script in `firebase/` that imported
// `firebase-admin` itself would get a second copy — and a `FieldValue` from one copy is not
// serialisable by the other. Importing the SDK from here keeps both sides on this copy.
export { applicationDefault, initializeApp } from 'firebase-admin/app';
export { getAuth } from 'firebase-admin/auth';
export { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
