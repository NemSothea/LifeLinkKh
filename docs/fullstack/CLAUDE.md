# Fullstack scope
The single build role. Write: firebase/ (firestore.rules + rules-tests/, functions/, seed/, scripts/), frontend/, docs/fullstack/ (specs/, api-contract/).
NOT root configs or deploys — CI, the Firebase project and `firebase deploy` belong to Tech Lead. `backend/` and Docker are gone (ADR 0009).
The data contract is `docs/tech-lead/firestore-data-model.md` + `firebase/firestore.rules`; a rule without a rules test is treated as absent. `api-contract/` is the Spring-era REST contract, kept as history.
Consume PO FRs; get Tech Lead (+ Security if R5) sign-off before merge. Ask PO via CR-PO. No DevOps role.
