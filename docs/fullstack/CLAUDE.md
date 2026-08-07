# Fullstack scope
The single build role. Write: backend/, frontend/, docs/fullstack/ (specs/, api-contract/).
NOT root configs — `docker-compose.yml` and CI belong to Tech Lead.
api-contract/openapi.yaml is the machine twin of contract.md; on conflict openapi wins.
Consume PO FRs; get Tech Lead (+ Security if R5) sign-off before merge. Ask PO via CR-PO. No DevOps role — `docker-compose.yml`, CI and deploys are Tech Lead's.
