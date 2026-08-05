# Graph Report - .  (2026-08-05)

## Corpus Check
- Corpus is ~35,724 words - fits in a single context window. You may not need a graph.

## Summary
- 389 nodes · 870 edges · 22 communities (20 shown, 2 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 154 edges (avg confidence: 0.89)
- Token cost: 370,513 input · 118,699 output

## Community Hubs (Navigation)
- PM Decisions & Product Changelog
- API Contracts & Foundation Specs
- Database Schema & Architecture
- Pitch Deck Generator
- Project Brief & Capybara Setup
- PO Brief & Prototype Process
- Governance Rulebook & Change Requests
- Course Assignment Requirements
- Core Features & Security Controls
- DevOps Deploy & CI
- Unresolved Request-Lifecycle Briefs
- Donor Profile, Matching & Privacy
- Donation History & Notification Volume
- Flutter Mobile & Milestone Docs
- Tech Stack & Two-Client Architecture
- Role Assignments & Concentration Risk
- Request Response & Prototype Cadence
- Phone OTP Authentication
- Khmer/English Localization
- validate.sh Script
- PO Feature Flow
- pre-commit Hook

## God Nodes (most connected - your core abstractions)
1. `LifeLink KH Product Requirements Document v1.0` - 60 edges
2. `Feature Registry Index` - 32 edges
3. `PO roadmap open briefs` - 23 edges
4. `FR-MATCH-001 Donor Matching` - 22 edges
5. `Prototype Roadmap` - 22 edges
6. `FR-NOTIFY-001 Request Push Alert` - 17 edges
7. `heading()` - 15 edges
8. `DEC-002 — Request-Alert Push to M4, FCM Token Registration to M3` - 15 edges
9. `footer()` - 14 edges
10. `main()` - 14 edges

## Surprising Connections (you probably didn't know these)
- `LifeLink KH Product Requirements Document v1.0` --implements--> `Requirement: One product idea — problem, target user, three features`  [INFERRED]
  docs/po/prd.md → Cross-Platform-Project-task.jpg
- `Team Responsibilities Table (CLAUDE.md §5)` --semantically_similar_to--> `Team — LifeLink KH`  [INFERRED] [semantically similar]
  CLAUDE.md → docs/team.md
- `CLAUDE.md project plan` --implements--> `Deliverable M7: Published to Play Store internal testing by Week 15`  [INFERRED]
  docs/po/features/FR-NOTIFY-001-request-push-alert.md → Cross-Platform-Project-task.jpg
- `CLAUDE.md project plan` --implements--> `Requirement: Defend 'why mobile, not just a website' in one sentence`  [INFERRED]
  docs/po/features/FR-NOTIFY-001-request-push-alert.md → Cross-Platform-Project-task.jpg
- `README Architecture Diagram` --semantically_similar_to--> `Two-Client / One-API Architecture`  [INFERRED] [semantically similar]
  README.md → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **R6 Definition of Done Gate — enforced across PR template, runbook, security review, and feature flow** — docs_cheat_sheet_r6_definition_of_done, _github_pull_request_template_dod_checklist, infra_deploy_pre_promotion_checklist, docs_security_reviews__template_security_review, docs_roles_and_flows_feature_flow, docs_team_role_qa [EXTRACTED 1.00]
- **R5 Security Overlay Flow — triggers, checklist, threat model, review note, CR-SEC channel** — _capybara_setup_r5_security_triggers, docs_security_security_checklist_security_checklist, docs_security_threat_models__template_threat_model, docs_security_reviews__template_security_review, docs_security_change_requests_cr_sec_index_cr_sec_registry, docs_security_claude_security_overlay_scope [EXTRACTED 1.00]
- **Three Core Features Share the 56-Day Eligibility Spine** — claude_donor_register, claude_urgent_request_broadcast, claude_donation_history_eligibility_reminder, claude_56_day_cooldown_rule, claude_fcm_push [EXTRACTED 1.00]
- **M2 Health-Check Wiring Chain (Backend → Contracts → Both Clients)** — docs_fullstack_specs_foundation_backend_spring_get_api_health, docs_fullstack_api_contract_mobile_openapi_mobile_api, docs_fullstack_api_contract_web_openapi_web_api, docs_fullstack_specs_foundation_frontend_nextjs_gethealth, docs_fullstack_specs_foundation_infra_docker_backend_service [EXTRACTED 1.00]
- **V1__init.sql Six-Entity Schema** — docs_fullstack_specs_foundation_backend_spring_users_table, docs_fullstack_specs_foundation_backend_spring_donor_profiles_table, docs_fullstack_specs_foundation_backend_spring_hospitals_table, docs_fullstack_specs_foundation_backend_spring_blood_requests_table, docs_fullstack_specs_foundation_backend_spring_request_matches_table, docs_fullstack_specs_foundation_backend_spring_donations_table [EXTRACTED 1.00]
- **Khmer-First Localization Across Both Clients** — docs_fullstack_specs_foundation_frontend_nextjs_khmer_default_locale, docs_fullstack_specs_foundation_frontend_nextjs_khmer_font_stack, docs_fullstack_specs_foundation_mobile_flutter_arb_localization, docs_fullstack_specs_foundation_mobile_flutter_khmer_text_metrics, docs_tech_lead_coding_standards_no_hardcoded_strings [INFERRED 0.85]
- **M4 Overload Chain: DEC-001 + DEC-002 → M4 Risk → Pre-Decided Cut Order** — docs_pm_decisions_dec_001, docs_pm_decisions_dec_002, docs_pm_risks_m4_overloaded, docs_pm_risks_cut_order_m4, docs_pm_risks_qa_independent_gate [EXTRACTED 1.00]
- **Urgent Request Core Loop (Create → Match → Push → Respond)** — docs_po_prd_fr_04, docs_po_prd_fr_05, docs_po_prd_fr_06, docs_po_prd_fr_07, docs_po_prd_entity_bloodrequest, docs_po_prd_entity_requestmatch [EXTRACTED 1.00]
- **56-Day Eligibility Lifecycle (Profile → Compute → Donation → Reminder)** — docs_po_prd_fr_02, docs_po_prd_fr_03, docs_po_prd_fr_08, docs_po_prd_fr_09, docs_po_prd_entity_donation, docs_po_prd_eligibility_cooldown [EXTRACTED 1.00]
- **Urgent request end-to-end flow (post → match → push → accept → confirm)** — docs_po_features_fr_request_001_create_urgent_request, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_notify_001_request_push_alert, docs_po_features_fr_request_002_respond_accept_decline, docs_po_features_fr_portal_001_hospital_request_management, docs_po_features_fr_donation_001_donation_history [EXTRACTED 1.00]
- **56-day eligibility loop (confirm → compute → remind → re-match)** — docs_po_features_fr_donation_001_donation_history, docs_po_features_fr_donor_002_eligibility_check, docs_po_features_fr_notify_002_eligibility_reminder, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_portal_001_hospital_request_management [INFERRED 0.95]
- **FRs blocked on unresolved roadmap briefs before M4 build** — docs_po_features_fr_donor_001_donor_profile, docs_po_features_fr_donor_002_eligibility_check, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_match_002_zero_match_fallback, docs_po_features_fr_request_004_withdraw_acceptance, docs_po_features_fr_request_005_request_expiry, docs_po_features_fr_security_001_account_data_deletion, docs_po_briefs_roadmap [EXTRACTED 1.00]
- **PO artifact pipeline: brief → prototype → FR → changelog** — docs_po_briefs_readme_brief, docs_po_prototypes_readme_prototype, docs_po_features__template, docs_po_briefs_readme_po_flow, docs_po_changelog [EXTRACTED 1.00]
- **M4 matching readiness: open briefs blocking match FRs and their prototype** — docs_po_briefs_roadmap_zero_match_fallback, docs_po_briefs_roadmap_max_notified_count, docs_po_briefs_roadmap_location_precision_vs_privacy, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_match_002_zero_match_fallback, docs_po_prototypes_roadmap_match_no_donors_found [EXTRACTED 1.00]
- **M1 wireframe deliverable — four PRD section-7 flows** — docs_po_prototypes_roadmap_auth_otp_signin, docs_po_prototypes_roadmap_donor_profile_setup, docs_po_prototypes_roadmap_request_create_urgent, docs_po_prototypes_roadmap_notify_donor_alert, docs_po_prd [EXTRACTED 1.00]

## Communities (22 total, 2 thin omitted)

### Community 0 - "PM Decisions & Product Changelog"
Cohesion: 0.07
Nodes (71): PM Scope (Coordination Overlay), DEC-001 — Eligibility Computation Moves to M4, DEC-002 — Request-Alert Push to M4, FCM Token Registration to M3, DEC-003 — Metrics Event Capture Is a Per-Milestone Requirement, Events Not Captured When They Happen Are Gone, Split FCM Into Token Registration (M3) and Send Path (M4), A Milestone Must Satisfy Its Own Acceptance Criteria, Decision Register (DEC) (+63 more)

### Community 1 - "API Contracts & Foundation Specs"
Cohesion: 0.05
Nodes (60): CR-MAPI Mobile API Change Request Log, SPEC-MOBILE-API-CONTRACT, bearerAuth JWT Security Scheme (Mobile), LifeLink KH Mobile API (OpenAPI 3.1), SPEC-WEB-API-CONTRACT, bearerAuth JWT Security Scheme (Web), LifeLink KH Web API (OpenAPI 3.1), Fullstack Role Scope (+52 more)

### Community 2 - "Database Schema & Architecture"
Cohesion: 0.12
Nodes (27): donations.donated_on As 56-Day Cooldown Source Of Truth, Blocked Decision — Donor Location Precision, Blocked Decision — Request Expiry, blood_requests Table, Blood Type VARCHAR(3) + CHECK Instead of ENUM, donations Table, donor_profiles Table, hospitals Table (+19 more)

### Community 3 - "Pitch Deck Generator"
Cohesion: 0.33
Nodes (25): blank(), bullets(), footer(), heading(), main(), notes(), parse_milestones(), Max 6 items, max 12 words each — detail belongs in the speaker notes.… (+17 more)

### Community 4 - "Project Brief & Capybara Setup"
Cohesion: 0.17
Nodes (21): LifeLink KH Project Brief, Sensitivity Declaration (R5): auth, PII, secrets, integrations, Capybara Setup State (tier: full), Capybara Stage Checklist (init done, project in progress), PR Change Type Prefixes (feat/fix/spec/adr/sec/qa/infra/docs/refactor/chore), Capybara ADK Orchestrator Verbs (/capybara-adk:*), LifeLink KH — Blood Donor Matching App, Why We Chose This Project (impact, grade-worthy tech, scope fit) (+13 more)

### Community 5 - "PO Brief & Prototype Process"
Cohesion: 0.13
Nodes (19): Cheat sheet (rulebook R1–R8), Briefs README — pre-FR thinking, R7 area taxonomy (AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL GLOBAL SECURITY MOBILE), Brief (Problem / Why now / Open questions), Brief naming convention BRIEF-<AREA>-<###>-<slug>, Dropped briefs stay in repo, PO flow: brief → prototype → FR, PO write-scope rule (PO writes docs/po/ only) (+11 more)

### Community 6 - "Governance Rulebook & Change Requests"
Cohesion: 0.21
Nodes (17): Feature Areas (brief, R7): AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL, Feature Areas (setup, R7) incl. GLOBAL SECURITY MOBILE, PR Template DoD Checklist (R6), index.md Merge Conflict = ID Allocation, R6 Definition of Done (5 gates), R7 ID Conventions (FR / BUG / ADR / CR / DEC), CR-DEVOPS Change Request Template, CR-DEVOPS Registry (any → DevOps, next: 001) (+9 more)

### Community 7 - "Course Assignment Requirements"
Cohesion: 0.19
Nodes (16): CLAUDE.md project plan, Assignment Slide Photo — Track B Team Product (Week 2 of 16), Cross-Platform Mobile App Development (16-week course), Requirement: One product idea — problem, target user, three features, Deliverable M7: Published to Play Store internal testing by Week 15, Requirement: 7 milestones M1 to M7 from Week 3 onward, Requirement: Teams of 3, formed by Monday and posted in class group, Track A (FieldLog) — Personal Capstone (+8 more)

### Community 8 - "Core Features & Security Controls"
Cohesion: 0.23
Nodes (14): R5 Security Triggers In Scope (auth, PII, secrets, external integrations), 56-Day Donation Cooldown Rule, Feature 3 — Donation History + Eligibility Reminder, Feature 1 — Donor Register with Eligibility Check, Firebase Cloud Messaging Push Notifications, M3–M5 Amendment by DEC-001/002/003, Feature 2 — Urgent Request Broadcast + Matching, Auth Controls (OTP rate-limit/expiry, JWT lifetime, server-side RBAC) (+6 more)

### Community 9 - "DevOps Deploy & CI"
Cohesion: 0.26
Nodes (13): R3 Stack Declaration (Spring Boot + PostgreSQL, Next.js, Flutter), CI Placeholder Pipeline (GitHub Actions), Flyway App Migrations (DB schema ownership), Blameless Postmortems, DevOps Write Scope, Infra Flow (DevOps owns pipeline + runbook; asks via CR-DEVOPS), Moeun Nithvaraman, Role: DevOps (docs/devops/ + infra/ + pipeline) (+5 more)

### Community 10 - "Unresolved Request-Lifecycle Briefs"
Cohesion: 0.23
Nodes (13): Backend Spring foundation spec, PO roadmap open briefs, Next brief number per area, Post-pilot out-of-scope backlog, Request expiry rule (brief), Withdrawn acceptance (brief), Zero-match fallback (brief), FR-MATCH-002 Zero-Match Fallback (+5 more)

### Community 11 - "Donor Profile, Matching & Privacy"
Cohesion: 0.19
Nodes (13): Availability toggle as its own behaviour (brief), Location precision vs. privacy (brief), Max-notified count (brief), FR-DONOR-001 Donor Profile, Donor availability toggle, Location-precision open brief (coordinates vs district centroid), FR-MATCH-001 Donor Matching, ABO/Rh compatibility matching (not exact-type) (+5 more)

### Community 12 - "Donation History & Notification Volume"
Cohesion: 0.18
Nodes (13): Donation without a request (brief), SMS budget and flood guard (resend cooldown), FR-DONATION-001 — Donation history, Hospital-confirmed donation record, 56-day donation cooldown rule, Metric event stream (created, notified, delivered, accepted, confirmed), Max notified count (open brief), FR-REQUEST-001 Create Urgent Request (+5 more)

### Community 13 - "Flutter Mobile & Milestone Docs"
Cohesion: 0.20
Nodes (12): Mobile Model Choice (R3): Flutter native Android, Flutter Mobile App (donors/patients, Play Store), Course Milestones M1–M7, Why Mobile, Not Just a Website, Chat ↔ Docs Boundary (decisions live in docs, not chat), Environments (local / dev / play-internal), API_BASE_URL dart-define Required (fail fast, no default host), Feature Registry — 19 FRs with area/priority/status/milestone (+4 more)

### Community 14 - "Tech Stack & Two-Client Architecture"
Cohesion: 0.25
Nodes (11): Two-Client / One-API Architecture, docker-compose Local Stack (postgres + backend + web), Khmer + English i18n (both clients), Next.js Web Portal (hospital/admin), PostgreSQL Database, Spring Boot API (JPA, Flyway, Spring Security), LifeLink KH Tech Stack, Role: Fullstack (backend/ + frontend/ + docs/fullstack/) (+3 more)

### Community 15 - "Role Assignments & Concentration Risk"
Cohesion: 0.24
Nodes (10): R2 Acting User Roles (solo driver session), Mobile Flow — CR-MAPI; mobile never writes backend code, Nem Sothea, Oun Sreynich, Role: Mobile (mobile/ + docs/mobile/), Role: PM Coordination Overlay (DoD tracking), Role: PO (docs/po/, team-owned), Role: QA (docs/qa/, test cases, bug registry, DoD sign-off) (+2 more)

### Community 16 - "Request Response & Prototype Cadence"
Cohesion: 0.22
Nodes (10): Root CLAUDE.md (M1–M7 milestone table), Brief cadence — promoted or dropped before build week, FR-REQUEST-002 — Respond to a request (accept or decline), Contact reveal only on acceptance (privacy model), Prototype Roadmap, DONOR-eligibility-status flow, NOTIFY-donor-alert flow, Prototype ships one milestone ahead of code (+2 more)

### Community 17 - "Phone OTP Authentication"
Cohesion: 0.28
Nodes (9): Frontend Next.js foundation spec, FR-AUTH-001 — Phone authentication via OTP, Passwordless phone-verified identity, FR-AUTH-002 — OTP resend with cooldown, Feature Registry Index, FRs blocked on open briefs, FR status semantics: accepted vs requested, AUTH-otp-signin flow (+1 more)

### Community 18 - "Khmer/English Localization"
Cohesion: 0.33
Nodes (6): FR-GLOBAL-001 — Khmer and English localization, Khmer-as-default layout constraint, Under-one-minute request form constraint, Khmer + English on every screen rule, GLOBAL-language-switch flow, Khmer pass at M6

### Community 20 - "PO Feature Flow"
Cohesion: 1.00
Nodes (3): docs/po/changelog.md as Forward Signal, Feature Flow (PO → sign-off → build → QA → security → DoD), PO Flow: brief → prototype → finalize FR

## Ambiguous Edges - Review These
- `WITHDRAWN Response Value Without An FR` → `Unresolved docker-compose.yml Ownership Contradiction`  [AMBIGUOUS]
  docs/fullstack/specs/foundation/infra-docker.md · relation: semantically_similar_to
- `FR-MATCH-001 Donor Matching` → `FR-REQUEST-004 — Donor withdraws acceptance`  [AMBIGUOUS]
  docs/po/features/FR-REQUEST-004-withdraw-acceptance.md · relation: conceptually_related_to

## Knowledge Gaps
- **26 isolated node(s):** `Feature Areas (setup, R7) incl. GLOBAL SECURITY MOBILE`, `Capybara Stage Checklist (init done, project in progress)`, `PR Change Type Prefixes (feat/fix/spec/adr/sec/qa/infra/docs/refactor/chore)`, `Track A (FieldLog) vs Track B (this team product)`, `README Architecture Diagram` (+21 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `WITHDRAWN Response Value Without An FR` and `Unresolved docker-compose.yml Ownership Contradiction`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `FR-MATCH-001 Donor Matching` and `FR-REQUEST-004 — Donor withdraws acceptance`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `LifeLink KH Product Requirements Document v1.0` connect `PM Decisions & Product Changelog` to `PO Brief & Prototype Process`, `Course Assignment Requirements`, `Unresolved Request-Lifecycle Briefs`, `Donor Profile, Matching & Privacy`, `Donation History & Notification Volume`, `Request Response & Prototype Cadence`, `Phone OTP Authentication`, `Khmer/English Localization`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **Why does `Feature Registry Index` connect `Phone OTP Authentication` to `PM Decisions & Product Changelog`, `PO Brief & Prototype Process`, `Course Assignment Requirements`, `Unresolved Request-Lifecycle Briefs`, `Donor Profile, Matching & Privacy`, `Donation History & Notification Volume`, `Request Response & Prototype Cadence`, `Khmer/English Localization`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `Prototype Roadmap` connect `Request Response & Prototype Cadence` to `PM Decisions & Product Changelog`, `PO Brief & Prototype Process`, `Course Assignment Requirements`, `Unresolved Request-Lifecycle Briefs`, `Donor Profile, Matching & Privacy`, `Donation History & Notification Volume`, `Phone OTP Authentication`, `Khmer/English Localization`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Feature Registry Index` (e.g. with `PO Scope` and `FR template`) actually correct?**
  _`Feature Registry Index` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `FR-MATCH-001 Donor Matching` (e.g. with `FR-DONOR-002 Eligibility Check` and `FR-DONOR-001 Donor Profile`) actually correct?**
  _`FR-MATCH-001 Donor Matching` has 6 INFERRED edges - model-reasoned connections that need verification._