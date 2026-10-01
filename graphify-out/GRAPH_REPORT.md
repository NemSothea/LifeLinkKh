# Graph Report - .  (2026-10-01)

## Corpus Check
- Large corpus: 787 files · ~840,677 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 3320 nodes · 6288 edges · 195 communities (165 shown, 30 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 205 edges (avg confidence: 0.86)
- Token cost: 1,026,927 input · 0 output

## Community Hubs (Navigation)
- Portal API Route Handlers
- Public Web Pages & Icons
- Portal Actions & API Client
- Donor Home Board Tests
- Drift Generated Schema
- Session Store & Auth Tests
- About & App Update Tests
- Mobile Bootstrap Imports
- UX Snapshot & Golden Tests
- Request Providers (Generated)
- Course Arch & Launch Audit
- Early Decisions & PRD Scope
- Spring Boot Foundation Spec
- Admin Dashboard Pages
- shadcn UI Primitives
- Rulebook & Core Rules
- Donor Setup Screens
- Home Tab Composition
- Security Tests & Reviews
- Portal Request Lists
- Core Service Providers
- Firebase Package Deps
- App Version Admin Form
- Donation History Tests
- Riverpod Repo Wiring
- M3 Google Sign-In Spec
- Community Launch Skill
- App Update Gate
- Auth Providers
- Pitch Deck Builder v2
- Mobile Failure Types
- Bugs & Risks
- Crash Handling Tests
- Demo Commands & Skills
- Briefs & Changelog
- Match & Account Services
- Pickers & Theme Widgets
- Request Domain & Firestore Data
- createRequest Function
- Frontend TS Config
- Frontend Runtime Deps
- Frontend Lint Deps
- Dashboard Filters & Data
- Request Form & Blood Guide
- Firebase Flow & Demo Runbook
- Pitch Deck Builder v1
- FCM Push & Inbox
- Repo Docs & CI Tooling
- Request Service Domain
- NBTC Letter & Eligibility
- Avatar Feature
- Capybara Brief Areas
- CI Workflow
- Me Tab
- Social Credentials
- Showcase Seed
- About & Sign-In UI
- Account Deletion
- Notification Inbox Providers
- App Router
- Donor Providers
- Matching & Cooldown
- ADR 0009 Firebase Move
- deleteAccount Function
- Change Password
- iOS Runner
- Localization & Brand Widgets
- User Guides & Features
- Portal Functions API Client
- FRs & Threat Model
- Notification Inbox Tests
- Splash & Share Art Tools
- Push Token Providers
- App Config Function
- Mobile Pubspec Deps
- Release & Deploy Runbook
- shadcn components.json
- Header Widgets & Bell
- App Update Providers
- App Shell & Offline
- Khmer Copy & Districts
- Telegram Sign-In (Dropped)
- Donation Providers
- ADR 0010 Portal Functions
- Match Sync DAO
- Book Deps
- Push Registration
- SEO & Sitemap
- About Providers
- M4 Matching Spec
- Firestore Data Model
- Excel Export
- confirmDonation Function
- Drift DAO Layer
- App Config Repository
- Notifications Screen
- Admin Seed & Accounts
- Production Checklist & Spark
- Postgres ERD (Legacy)
- Week 3 Course Slides
- Auth Service Domain
- Firestore Rules Tests
- respondToMatch Function
- Bar Chart
- Credential Adapters
- Match Detail Screen
- Project Plan & Milestones
- Metrics Script
- Release Script
- Demo Seed
- Frontend Package Meta
- Week 4 Riverpod Slides
- Notification Inbox Repo
- Auth Repository
- Book Package Meta
- Decisions Generator
- ADR 0008 Notify Cap
- Frontend Scripts
- Locale Layout
- Request Lifecycle Tests
- Connectivity Providers
- App Theme
- Donor Domain Models
- Book Browserslist
- Book Dev Deps
- ADR 0007 Session Lifetime
- Donor Repository
- Book Scripts
- Book TS Config
- i18n Routing
- Week 5 Async Slides
- Week 6 Sealed Errors
- Env & Crash Handling
- Intro Screen
- Android MainActivity
- Profile Avatar Painter
- Drift Data Classes
- reviewRequest Function
- Match Domain
- Base Seed
- Next Config
- Prettier Config
- Link Opener
- Roles & Templates
- ESLint Config
- Invoke Tests
- Result Type
- Geohash
- Report Repository
- Secrets History Scan
- verify.mjs
- vercel.json
- app_config.dart
- auth_user.dart
- validate.sh
- frontend AGENTS.md: Next.js agent rules
- session.test.ts
- PendingSync
- reauthentication.dart
- app_notification.dart
- integration_test.dart
- demo-mobile.sh
- verify-all.sh
- docusaurus.config.ts
- sidebars.ts
- CR-PO index
- build.sh
- tailwindcss
- @types/react
- @vitejs/plugin-react
- postcss.config.mjs
- vitest.server.config.ts
- pre-commit
- user_role.dart
- donation.dart
- blood_type.dart
- donor_sex.dart
- match_response_type.dart
- hospital.dart
- request_status.dart
- requester_contact.dart
- build-release-apk.sh
- @visibleForTesting
- FunctionProvider
- requestDetailProvider

## God Nodes (most connected - your core abstractions)
1. `cn()` - 53 edges
2. `README` - 35 edges
3. `Feature Registry (FR index)` - 29 edges
4. `LifeLink KH project plan (CLAUDE.md)` - 27 edges
5. `DEC-019 Cambodian/NBTC medical practice, 90/120-day cooldown` - 22 edges
6. `ADR 0003 Donor Location Precision` - 22 edges
7. `ADR 0010: Portal's server runs the functions; Cloud Functions and Blaze go` - 22 edges
8. `firestoreQuery()` - 20 edges
9. `DEC-004 Scope cut / no map widget` - 20 edges
10. `community-launch skill` - 19 edges

## Surprising Connections (you probably didn't know these)
- `Contributing guide (Khmer)` --semantically_similar_to--> `Contributing guide`  [INFERRED] [semantically similar]
  CONTRIBUTING.km.md → CONTRIBUTING.md
- `Team onboarding` --semantically_similar_to--> `Contributing guide`  [INFERRED] [semantically similar]
  ONBOARDING.md → CONTRIBUTING.md
- `Five PRD success metrics (npm run metrics)` --conceptually_related_to--> `DEC-015 Admin approves request before alert`  [INFERRED]
  docs/demo-runbook.md → .claude/RESUME.md
- `scripts/verify-all.sh` --semantically_similar_to--> `CI workflow`  [EXTRACTED] [semantically similar]
  .claude/RESUME.md → .github/workflows/ci.yml
- `ADR 0002 Google Sign-In over phone OTP` --conceptually_related_to--> `Unverified donor phone numbers risk`  [INFERRED]
  README.md → docs/risks.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **The five portal server functions (ADR 0010)** — concept_fn_createrequest, concept_fn_reviewrequest, concept_fn_respondtomatch, concept_fn_confirmdonation, concept_fn_deleteaccount, concept_portal_functions [EXTRACTED 1.00]
- **Community launch phases 0-7** — _claude_skills_community_launch_skill_phase0_audit, _claude_skills_community_launch_skill_phase1_oss_readiness, _claude_skills_community_launch_skill_phase2_community_infra, _claude_skills_community_launch_skill_phase3_seo, _claude_skills_community_launch_skill_phase4_book, _claude_skills_community_launch_skill_phase5_mobile_distribution, _claude_skills_community_launch_skill_phase6_launch, _claude_skills_community_launch_skill_phase7_update_cadence [EXTRACTED 1.00]
- **Open-source readiness files (Phase 1)** — security, code_of_conduct, contributing, contributing_km, _github_issue_template_bug, _github_issue_template_feature, _github_issue_template_translation, _github_issue_template_config [INFERRED 0.95]
- **Admin-gated request review flow (PENDING -> approve/reject -> match)** — docs_decisions_dec_015, docs_decisions_pending_request_state, docs_book_i18n_en_docusaurus_plugin_content_docs_current_requester_guide_requester_guide, docs_demo_runbook_golden_path, docs_demo_runbook_admin_soborey [INFERRED 0.85]
- **DEC-019 Cambodian-practice guidance surfaces** — docs_decisions_dec_019, docs_book_i18n_en_docusaurus_plugin_content_docs_current_donor_guide_donation_interval, docs_book_i18n_en_docusaurus_plugin_content_docs_current_requester_guide_replacement_donation, docs_book_i18n_en_docusaurus_plugin_content_docs_current_requester_guide_blood_is_free, docs_book_i18n_en_docusaurus_plugin_content_docs_current_donor_guide_report_request, docs_book_i18n_en_docusaurus_plugin_content_docs_current_donor_guide_pre_accept_self_check [INFERRED 0.85]
- **Location privacy: district only, coordinates never returned** — docs_decisions_adr_0003, docs_fullstack_api_contract_mobile_contract_response_rules, docs_fullstack_api_contract_mobile_change_requests_cr_mapi_004, docs_fullstack_api_contract_web_contract_open_requests_table, docs_book_i18n_en_docusaurus_plugin_content_docs_current_faq_privacy_visibility [INFERRED 0.85]
- **POST /requests match-and-push flow** — docs_fullstack_specs_features_request_and_matching_post_requests, docs_fullstack_specs_features_request_and_matching_matching_query, docs_fullstack_specs_foundation_backend_spring_request_matches_table, docs_fullstack_specs_features_request_and_matching_fcm_donor_push, docs_po_features_fr_match_001_donor_matching_candidate_filter, docs_po_features_fr_match_001_donor_matching_max_notified_25 [EXTRACTED 1.00]
- **Google Sign-In security controls (TM-AUTH-001)** — docs_fullstack_specs_features_auth_google_sign_in_identity_from_sub, docs_fullstack_specs_features_auth_google_sign_in_aud_iss_check, docs_fullstack_specs_features_auth_google_sign_in_role_allow_list, docs_fullstack_specs_features_auth_google_sign_in_verifyidtoken, docs_fullstack_specs_features_auth_google_sign_in_signin_rate_limit, docs_fullstack_specs_features_auth_google_sign_in_auth_logging [EXTRACTED 1.00]
- **Offline-first accept/decline sync** — docs_mobile_local_db_and_sync_drift_database, docs_mobile_local_db_and_sync_pending_sync, docs_mobile_local_db_and_sync_syncservice, docs_mobile_local_db_and_sync_idempotency_key, docs_mobile_local_db_and_sync_offline_first_match_repository, docs_mobile_local_db_and_sync_server_wins [EXTRACTED 1.00]
- **Urgent request -> push -> accept -> confirm loop** — docs_po_features_fr_request_001_create_urgent_request, docs_po_features_fr_notify_001_request_push_alert, docs_po_features_fr_request_002_respond_accept_decline, docs_po_features_fr_notify_003_requester_acceptance_push, docs_po_prototypes_web_portal_open_requests_readme_confirm_donation [INFERRED 0.85]
- **FRs deferred by DEC-004 scope cut** — docs_po_features_fr_match_002_zero_match_fallback, docs_po_features_fr_notify_002_eligibility_reminder, docs_po_features_fr_portal_002_admin_dashboard, docs_po_features_fr_request_003_duplicate_request_warning, docs_po_features_fr_request_004_withdraw_acceptance, docs_po_features_fr_request_005_request_expiry, docs_po_features_fr_security_001_account_data_deletion [EXTRACTED 1.00]
- **Donor privacy model (contact only after accept)** — docs_po_prd_sensitive_data_rules, docs_po_prototypes_mobile_request_responders_list_readme_one_directional_reveal, docs_po_features_fr_request_002_respond_accept_decline, docs_po_prototypes_mobile_notify_donor_alert_readme, docs_po_prototypes_web_portal_open_requests_readme [INFERRED 0.85]
- **NBTC outreach package (letters + checklist)** — docs_po_research_letter_src_letter_en_nbtc_letter_en, docs_po_research_letter_src_letter_km_nbtc_letter_km, docs_po_research_nbtc_letter_en, docs_po_research_nbtc_letter_km, docs_po_research_nbtc_confirmation_checklist_checklist [INFERRED 0.85]
- **Google Sign-In R5 security gate (ADR, threat model, review, test case)** — docs_tech_lead_adr_0002_auth_google_sign_in, docs_security_threat_models_tm_auth_001_google_sign_in, docs_security_reviews_sec_review_001_google_sign_in, docs_qa_test_cases_tc_auth_001_google_sign_in_security [EXTRACTED 1.00]
- **Firebase stack security review cycle** — docs_security_reviews_sec_review_003_firebase_stack, docs_security_reviews_sec_review_004_remediation, docs_security_asvs_baseline, docs_security_security_checklist, docs_security_reviews_sec_review_005_masvs_mobile [EXTRACTED 1.00]
- **M2 verification defects closed in d1f5efd** — docs_qa_bugs_bug_infra_001_postgres_port_5432_occupied, docs_qa_bugs_bug_web_002_next_standalone_binds_container_id, docs_qa_bugs_bug_build_003_testcontainers_skips_with_docker_running [EXTRACTED 1.00]
- **Portal functions replacing Cloud Functions** — docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_createrequest, docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_respondtomatch, docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_reviewrequest, docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_deleteaccount, docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_confirmdonation [EXTRACTED 1.00]
- **Backend migration decisions (session -> Firebase -> portal functions)** — docs_tech_lead_adr_0007_session_lifetime_and_expiry_doc, docs_tech_lead_adr_0009_firebase_replaces_spring_boot_and_postgres_doc, docs_tech_lead_adr_0010_portal_functions_replace_cloud_functions_doc, docs_tech_lead_adr_index_doc [EXTRACTED 1.00]
- **Runbooks from local dev to production** — docs_tech_lead_local_development_doc, docs_tech_lead_deploy_runbook_doc, docs_tech_lead_production_checklist_doc, firebase_readme_doc [EXTRACTED 1.00]
- **Course state/error progression W3-W6** — mobile_docslesson_003_cp_mobile_week3_slides_service_pattern, mobile_docslesson_004_cp_mobile_week4_slides_notifier, mobile_docslesson_005_cp_mobile_week5_slides_asyncnotifier, mobile_docslesson_006_cp_mobile_week6_slides_result_type [INFERRED 0.85]

## Communities (195 total, 30 thin omitted)

### Community 0 - "Portal API Route Handlers"
Cohesion: 0.06
Nodes (56): DELETE, dynamic, GET(), maxDuration, PATCH, POST(), PUT, reply() (+48 more)

### Community 1 - "Public Web Pages & Icons"
Cohesion: 0.06
Nodes (41): ADR-0007, generateMetadata(), generateMetadata(), generateMetadata(), Section, Step, TeamMember, generateMetadata() (+33 more)

### Community 2 - "Portal Actions & API Client"
Cohesion: 0.07
Nodes (51): confirmDonationAction(), reviewRequestAction(), AppConfig, AppConfigInput, getAppConfig(), setAppConfig(), listPublicRequests(), PublicDonor (+43 more)

### Community 3 - "Donor Home Board Tests"
Cohesion: 0.06
Nodes (56): Card, MatchRepository, _EmptyMatches, _FakeMatchRepository, main, _match, _request, _settle (+48 more)

### Community 4 - "Drift Generated Schema"
Cohesion: 0.03
Nodes (60): ColumnFilters, ColumnOrderings, DateTime?, GeneratedColumn, GeneratedDatabase, int get, List, _openConnection (+52 more)

### Community 5 - "Session Store & Auth Tests"
Cohesion: 0.05
Nodes (48): SecureSessionStore, SessionStore, _InMemorySessionStore, main, _session, _uid, main, main (+40 more)

### Community 6 - "About & App Update Tests"
Cohesion: 0.07
Nodes (46): _bring, main, _config, _download, main, main, main, _match (+38 more)

### Community 7 - "Mobile Bootstrap Imports"
Cohesion: 0.04
Nodes (40): ../api/portal_api.dart, dart:ui, ../domain/update_dismissal_store.dart, failure.dart, locale_store.dart, main, failureFromFirebase, failureFromPortalCall (+32 more)

### Community 8 - "UX Snapshot & Golden Tests"
Cohesion: 0.06
Nodes (40): FilledButton, main, _app, main, main, _wrap, _completeIdentityStep, _completeSetup (+32 more)

### Community 9 - "Request Providers (Generated)"
Cohesion: 0.05
Nodes (44): @Deprecated, AutoDisposeFutureProvider, AutoDisposeFutureProviderElement, AutoDisposeFutureProviderRef, class, ../data/firestore_request_repository.dart, Iterable, hospitalsProvider (+36 more)

### Community 10 - "Course Arch & Launch Audit"
Cohesion: 0.05
Nodes (45): Dart/Flutter: MVVM, feature-first, repository-only Firestore access, Community launch — Phase 0 audit, Missing CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, issue templates, No GitHub Release or checksum for APK, Public repo with no LICENSE (top blocker), Secrets audit: service-account key never committed; gitleaks pending, SEO gaps: no sitemap/robots/hreflang/canonical, /sign-in indexable, SEO report — web portal (+37 more)

### Community 11 - "Early Decisions & PRD Scope"
Cohesion: 0.10
Nodes (44): DEC-002, DEC-003, DEC-004 Scope cut / no map widget, Brief Roadmap, Brief backlog by milestone, FR template, FR-GLOBAL-002 Metrics instrumentation (deferred), FR-MATCH-002 No-donors-found handling (+36 more)

### Community 12 - "Spring Boot Foundation Spec"
Cohesion: 0.07
Nodes (44): Deny-by-default SecurityConfig, POST /matches/{id}/respond, V6 request_matches.distance_km, Foundation Spec: Spring Boot + PostgreSQL, blood_requests table, Domain-module package layout kh.lifelink.api, donations table, Flyway migrations (never edited after merge) (+36 more)

### Community 13 - "Admin Dashboard Pages"
Cohesion: 0.11
Nodes (30): AppVersionPage(), DashboardPage(), PortalPage(), sortByUrgency(), URGENCY_RANK, AccountMenu(), arc(), PieChart() (+22 more)

### Community 14 - "shadcn UI Primitives"
Cohesion: 0.09
Nodes (29): Alert(), AlertDescription(), AlertTitle(), alertVariants, Badge(), badgeVariants, Card(), CardAction() (+21 more)

### Community 15 - "Rulebook & Core Rules"
Cohesion: 0.07
Nodes (41): $0 rule (no paid services), Who sees location / phone (district only; contact after accept), Capybara cheat sheet, Definition of Done (R6), Registry ID conventions (R7: FR, BUG, ADR, CR, DEC), 56-day eligibility cooldown (FR-DONOR-002, superseded), ADR 0002 Google Sign-In auth, ADR 0003 Donor location precision (+33 more)

### Community 16 - "Donor Setup Screens"
Cohesion: 0.07
Nodes (30): ../application/donor_providers.dart, ../application/donor_setup_controller.dart, blood_type_grid.dart, ../../../core/error/failure.dart, ../../../core/location/geohash.dart, ../../../core/location/location_providers.dart, ../../../core/widgets/searchable_picker.dart, district_dropdown.dart (+22 more)

### Community 17 - "Home Tab Composition"
Cohesion: 0.07
Nodes (34): ../application/donation_providers.dart, ../../../core/widgets/retryable_failure.dart, ../../donor/domain/donor_profile.dart, ../../donor/presentation/donor_setup_screen.dart, ../../donor/presentation/eligibility_card.dart, ../../match/application/match_providers.dart, ../../match/domain/match.dart, ../../match/domain/match_response_type.dart (+26 more)

### Community 18 - "Security Tests & Reviews"
Cohesion: 0.09
Nodes (38): TC-AUTH-001 Google Sign-In Security Tests, Case 12: donor contact & location exposure, Firebase project as QA blocker, FR-AUTH-003 Google Sign-In, Non-negotiable security tests, The 8 built FRs (DEC-004), FR-SECURITY-001 Account and data deletion, OWASP ASVS Baseline (+30 more)

### Community 19 - "Portal Request Lists"
Cohesion: 0.09
Nodes (29): FulfilledList(), FulfilledRow, PendingReviewList(), Copy, donorKey(), DonorViewModel, progressStyle(), RequestList() (+21 more)

### Community 20 - "Core Service Providers"
Cohesion: 0.06
Nodes (31): app_database.dart, appDatabaseProvider, device_location_service.dart, link_opener.dart, linkOpenerProvider, location_service.dart, appDatabase, firestoreProvider (+23 more)

### Community 21 - "Firebase Package Deps"
Cohesion: 0.06
Nodes (35): firebase, devDependencies, firebase, firebase-admin, @firebase/rules-unit-testing, firebase-tools, geofire-common, vitest (+27 more)

### Community 22 - "App Version Admin Form"
Cohesion: 0.11
Nodes (23): AppVersionResult, isWebLink(), saveAppVersionAction(), AppVersionForm(), Copy, ConfirmDonationForm(), Copy, Copy (+15 more)

### Community 23 - "Donation History Tests"
Cohesion: 0.08
Nodes (31): DonationRepository, _EmptyDonations, _donation, _FakeDonationRepository, main, _MutableDonationRepository, _wrap, _FakeDonationRepository (+23 more)

### Community 24 - "Riverpod Repo Wiring"
Cohesion: 0.08
Nodes (33): _, accountRepositoryProvider, @Riverpod, firestoreRequestRepositoryProvider, matchRepositoryProvider, matchSyncDaoProvider, localeControllerProvider, LocaleController (+25 more)

### Community 25 - "M3 Google Sign-In Spec"
Cohesion: 0.08
Nodes (35): M3 Build Spec: Google Sign-In, JWT, FCM token, aud + iss pinning (S2), Auth logging without secrets (R1, I2), 503 AUTH_PROVIDER_UNCONFIGURED on missing credentials, Backend HS256 JWT, 1h lifetime, GoogleTokenVerifier seam, Identity only from token sub (S1), POST /auth/fcm-token (+27 more)

### Community 26 - "Community Launch Skill"
Cohesion: 0.09
Nodes (34): community-launch skill, Core Web Vitals targets (LCP<2.5s, CLS<0.1, INP<200ms), gitleaks full-history secrets scan, JSON-LD Organization/WebSite/MobileApplication, License choice (MIT / Apache-2.0 / AGPL-3.0), Phase 0 Audit, Phase 1 Open-source readiness, Phase 2 Community infrastructure (+26 more)

### Community 27 - "App Update Gate"
Cohesion: 0.09
Nodes (31): ../application/app_update_providers.dart, ConsumerState, ConsumerStatefulWidget, ../../../core/links/link_providers.dart, ../domain/app_update.dart, ../../donation/presentation/donation_history_screen.dart, home_tab.dart, me_tab.dart (+23 more)

### Community 28 - "Auth Providers"
Cohesion: 0.06
Nodes (32): auth_service.dart, authRepositoryProvider, ../../../core/database/database_providers.dart, ../data/firebase_auth_repository.dart, ../data/firebase_facebook_credentials.dart, ../data/firebase_google_credentials.dart, ../data/secure_session_store.dart, facebookCredentialsProvider (+24 more)

### Community 29 - "Pitch Deck Builder v2"
Cohesion: 0.26
Nodes (32): blank(), bullets(), footer(), heading(), main(), notes(), parse_milestones(), Max 6 items, max 12 words each — detail belongs in the speaker notes.… (+24 more)

### Community 30 - "Mobile Failure Types"
Cohesion: 0.11
Nodes (26): ConflictFailure, Failure, ForbiddenFailure, NetworkFailure, NotFoundFailure, RateLimitedFailure, ServerFailure, UnauthorizedFailure (+18 more)

### Community 31 - "Bugs & Risks"
Cohesion: 0.09
Nodes (31): Bug Template, BUG-API-004 Donor District Not Localized, districtLabel(district, locale), DistrictName {km, en} schema, BUG-BUILD-003 Testcontainers Skips, docker.api.version surefire property (1.44), SchemaIntegrationTest, BUG-INFRA-001 Postgres Port 5432 Occupied (+23 more)

### Community 32 - "Crash Handling Tests"
Cohesion: 0.08
Nodes (28): ErrorWidget, RequestRepository, _EmptyRequests, _localized, main, _FakeRequestRepository, _FakeRequestRepository, _FakeRequestRepository (+20 more)

### Community 33 - "Demo Commands & Skills"
Cohesion: 0.11
Nodes (30): /milestone-signoff command, /verify-all command, run-demo skill, Emulator stack delivers no pushes (FCM has no emulator), Golden path rules (two Google accounts, donor on Android), Pre-flight match check (donors, fcmToken, matches), Code of Conduct (Contributor Covenant 2.1), docs/decisions.md decision record (+22 more)

### Community 34 - "Briefs & Changelog"
Cohesion: 0.09
Nodes (30): Eligibility computed on read (56-day), Requester acceptance push (FR-NOTIFY-003), BRIEF-DONATION-001 What to expect when you donate, What-to-expect donation guide, BRIEF-NOTIFY-001 Tell the requester a donor is coming, One-way push gap, Briefs README, Brief file shape (Problem/Why now/Open questions) (+22 more)

### Community 35 - "Match & Account Services"
Cohesion: 0.09
Nodes (27): account_deletion_service.dart, ../../../core/api/portal_api_providers.dart, ../data/firestore_match_repository.dart, ../data/functions_account_repository.dart, ../data/offline_first_match_repository.dart, match_service.dart, match_sync_service.dart, myMatchesControllerProvider (+19 more)

### Community 36 - "Pickers & Theme Widgets"
Cohesion: 0.09
Nodes (23): ../../../core/theme/app_theme.dart, ../../../core/widgets/guide_section.dart, ../../donor/domain/donor_sex.dart, _PickerSheet, _PickerSheetState, SearchablePicker, AvatarGender, AvatarSpec (+15 more)

### Community 37 - "Request Domain & Firestore Data"
Cohesion: 0.10
Nodes (20): blood_request.dart, blood_request_draft.dart, ../../../core/error/firestore_failure_mapper.dart, ../../../core/error/result.dart, ../domain/app_config.dart, ../domain/app_config_repository.dart, ../domain/donation.dart, ../domain/donation_repository.dart (+12 more)

### Community 38 - "createRequest Function"
Cohesion: 0.10
Nodes (19): BLOOD_TYPES, createRequest(), invalid(), ADR-0009, ADR-0010, URGENCIES, CODES, HttpsError (+11 more)

### Community 39 - "Frontend TS Config"
Cohesion: 0.07
Nodes (27): compilerOptions, allowJs, esModuleInterop, incremental, isolatedModules, jsx, lib, module (+19 more)

### Community 40 - "Frontend Runtime Deps"
Cohesion: 0.07
Nodes (27): class-variance-authority, dependencies, class-variance-authority, clsx, firebase-admin, lucide-react, next, next-intl (+19 more)

### Community 41 - "Frontend Lint Deps"
Cohesion: 0.07
Nodes (27): eslint, eslint-config-next, @eslint/eslintrc, devDependencies, eslint, eslint-config-next, @eslint/eslintrc, jsdom (+19 more)

### Community 42 - "Dashboard Filters & Data"
Cohesion: 0.11
Nodes (22): DashboardFilters(), iso(), Input(), Doc, BLOOD_TYPES, bucketKey(), bucketKeys(), computeDashboard() (+14 more)

### Community 43 - "Request Form & Blood Guide"
Cohesion: 0.09
Nodes (21): ../application/report_providers.dart, ../application/request_form_controller.dart, ../application/request_providers.dart, blood_guide_screen.dart, ../../../core/widgets/inline_error.dart, ../../../core/widgets/money_notice.dart, ../../donor/presentation/blood_type_grid.dart, Hospital (+13 more)

### Community 44 - "Firebase Flow & Demo Runbook"
Cohesion: 0.09
Nodes (26): Firebase Cloud Messaging push alerts, reviewRequest function, Four-step flow: request, admin review, alert, donor accepts, Contributing guide (book, EN), Contribution rules (bilingual strings, no real personal data, rules need tests, verify-all), Run locally on Firebase emulators in ~15 minutes, Donor alert conditions (compatible, available, eligible, within 10 km, admin-checked), Khmer-English glossary (+18 more)

### Community 45 - "Pitch Deck Builder v1"
Cohesion: 0.33
Nodes (25): blank(), bullets(), footer(), heading(), main(), notes(), parse_milestones(), Max 6 items, max 12 words each — detail belongs in the speaker notes.… (+17 more)

### Community 46 - "FCM Push & Inbox"
Cohesion: 0.18
Nodes (20): ANDROID_CHANNEL_ID, buildMessage(), DEAD_TOKEN_CODES, fileInInbox(), inboxEntry(), ADR-0009, render(), sendAll() (+12 more)

### Community 47 - "Repo Docs & CI Tooling"
Cohesion: 0.12
Nodes (25): gen-decisions.mjs (Decisions chapter generator), Dependabot config, SEC-REVIEW-003 F-09 vulnerable dependencies finding, book GitHub Pages workflow, Available-for-requests switch, Bilingual Docusaurus handbook (docs/book/), feat/firebase-backend branch, createRequest function (+17 more)

### Community 48 - "Request Service Domain"
Cohesion: 0.10
Nodes (18): ../../../core/phone/cambodian_phone.dart, ../domain/blood_request.dart, ../domain/blood_request_draft.dart, ../domain/hospital.dart, ../domain/request_repository.dart, ../domain/request_status.dart, ../domain/requester_contact.dart, ../domain/urgency.dart (+10 more)

### Community 49 - "NBTC Letter & Eligibility"
Cohesion: 0.11
Nodes (25): Admin reviews each request before alerting donors, Donation interval 90 days (men) / 120 days (women), Donor eligibility criteria (age 18-60, 45 kg, haemoglobin), Portal page /en/getting-blood, National Blood Transfusion Center (NBTC), NBTC Letter (English translation), No NBTC name/logo or 'confirmed by NBTC' without permission, OWASP ASVS 5.0 Level 1 self-assessment (+17 more)

### Community 50 - "Avatar Feature"
Cohesion: 0.12
Nodes (19): avatar_spec.dart, ../domain/avatar_account.dart, ../domain/avatar_spec.dart, ../domain/avatar_store.dart, ../../donor/application/donor_providers.dart, avatarAccountProvider, AvatarController, avatarStore (+11 more)

### Community 51 - "Capybara Brief Areas"
Cohesion: 0.10
Nodes (22): Capybara Project Brief, AUTH feature area, DONATION feature area, DONOR feature area, MATCH feature area, NOTIFY feature area, PORTAL feature area, REQUEST feature area (+14 more)

### Community 52 - "CI Workflow"
Cohesion: 0.15
Nodes (22): /fr-security-check command, CI workflow, Pinned Flutter 3.44.6 (not unpinned stable), Golden tests excluded on Linux CI, firebase CI job (rules + server functions on emulators), mobile CI job (flutter analyze/test), web CI job (lint, tsc, vitest), npm install instead of npm ci (macOS lockfile) (+14 more)

### Community 53 - "Me Tab"
Cohesion: 0.11
Nodes (20): ../../account/presentation/delete_account_screen.dart, ../../avatar/application/avatar_providers.dart, ../../avatar/presentation/avatar_picker_sheet.dart, ../../avatar/presentation/profile_avatar.dart, ConsumerWidget, ../../donation/presentation/donation_guide_screen.dart, ../../donor/presentation/donor_profile_screen.dart, LifeLinkApp (+12 more)

### Community 54 - "Social Credentials"
Cohesion: 0.10
Nodes (18): ../domain/google_credentials.dart, ../domain/reauthentication.dart, firebase_google_credentials.dart, LoginBehavior get, facebookCredentialFor, _loginBehavior, _randomNonce, isUserCancel (+10 more)

### Community 55 - "Showcase Seed"
Cohesion: 0.10
Nodes (17): ADMIN, ago(), approve(), db, DISTRICT, donorIds, DONORS, HOSPITAL (+9 more)

### Community 56 - "About & Sign-In UI"
Cohesion: 0.10
Nodes (17): ../../about/application/about_providers.dart, ../../about/presentation/about_screen.dart, ../application/about_providers.dart, ../application/auth_providers.dart, auth_failure_message.dart, ../../../core/widgets/brand_badge.dart, ../../../core/widgets/launch_splash.dart, CambodianPhone (+9 more)

### Community 57 - "Account Deletion"
Cohesion: 0.10
Nodes (17): account_deletion.dart, ../application/account_deletion_service.dart, ../application/account_providers.dart, ../../auth/domain/facebook_credentials.dart, ../../auth/domain/google_credentials.dart, ../../auth/domain/reauthentication.dart, ../../auth/domain/session_store.dart, ../../../core/api/portal_api.dart (+9 more)

### Community 58 - "Notification Inbox Providers"
Cohesion: 0.13
Nodes (19): ../../auth/application/auth_providers.dart, ../../auth/domain/auth_session.dart, inboxReadMarksProvider, unreadNotificationCountProvider, inbox, InboxReadMarks, notificationInboxRepository, unreadNotificationCount (+11 more)

### Community 59 - "App Router"
Cohesion: 0.10
Nodes (20): ChangeNotifier, ../core/widgets/route_not_found_screen.dart, ../features/about/presentation/about_screen.dart, ../features/account/presentation/delete_account_screen.dart, ../features/auth/presentation/sign_in_screen.dart, ../features/donation/presentation/donation_guide_screen.dart, ../features/donation/presentation/donation_history_screen.dart, ../features/donor/presentation/donor_profile_screen.dart (+12 more)

### Community 60 - "Donor Providers"
Cohesion: 0.11
Nodes (20): ../data/firestore_donor_repository.dart, donor_service.dart, donorRepositoryProvider, FutureProviderRef, districtsProvider, donorProfileControllerProvider, districts, DonorProfileController (+12 more)

### Community 61 - "Matching & Cooldown"
Cohesion: 0.15
Nodes (17): ADR-0004, ADR-0008, COOLDOWN_DAYS, COOLDOWN_DAYS_UNSPECIFIED, cooldownDaysFor(), distanceKm(), ADR-0003, ADR-0009 (+9 more)

### Community 62 - "ADR 0009 Firebase Move"
Cohesion: 0.11
Nodes (21): Cloud Functions on Blaze plan (matching, pushes, confirmDonation), Course risk: graded M1-M2 stack was Spring Boot + PostgreSQL, ADR 0009: Firebase replaces Spring Boot and PostgreSQL, Firestore is the database, Six-phase migration (golden path go/no-go at phase 3), Portal reads Firebase over REST from the Next server, Requester contact in requests/{id}/private/contact, Roles as custom claims + admins/{uid} record (+13 more)

### Community 63 - "deleteAccount Function"
Cohesion: 0.14
Nodes (12): auth, ADR-0010, uid, boardId(), commitInChunks(), deleteAccount(), deleteAccountData(), LIVE (+4 more)

### Community 64 - "Change Password"
Cohesion: 0.17
Nodes (14): changePasswordAction(), ChangePasswordResult, ChangePasswordForm(), Copy, claims(), portalToken(), portalUserId(), portalUsername() (+6 more)

### Community 65 - "iOS Runner"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 66 - "Localization & Brand Widgets"
Cohesion: 0.13
Nodes (13): AppLocalizations, brand_badge.dart, ../error/failure.dart, ../../../../l10n/app_localizations.dart, BrandBadge, InlineError, LaunchSplash, LaunchSplashApp (+5 more)

### Community 67 - "User Guides & Features"
Cohesion: 0.15
Nodes (20): Feature 3: Donation history + eligibility reminder, Feature 1: Donor register + 56-day eligibility, Donation eligibility cooldown, confirmDonation function, deleteAccount function, Donation interval: 90 days men / 120 days women or unspecified, Donor guide (book, EN), Pre-accept self-check deferrals (e.g. under 45 kg) (+12 more)

### Community 68 - "Portal Functions API Client"
Cohesion: 0.11
Nodes (17): ../config/env.dart, Exception, firebaseFunctionsProvider, functions_portal_api.dart, FunctionsPortalApi, PortalApi, PortalCallException, firebaseFunctions (+9 more)

### Community 69 - "FRs & Threat Model"
Cohesion: 0.14
Nodes (20): FR-PORTAL-001 Hospital request management (web), FR-PORTAL-003 Admin-managed staff accounts, No email storage (promote by display name), 56-day cooldown rule, PRD FR-03 Eligibility Check (cooldown), PRD FR-08 Donation History, PRD FR-10 Hospital Request Management, AUTH-google-signin prototype (+12 more)

### Community 70 - "Notification Inbox Tests"
Cohesion: 0.11
Nodes (17): Badge, dart:async, _app, _badgeText, _entry, main, main, _wrap (+9 more)

### Community 71 - "Splash & Share Art Tools"
Cohesion: 0.11
Nodes (17): Color, dart:io, _Banner, _loadFonts, main, _red, _render, _canvas (+9 more)

### Community 72 - "Push Token Providers"
Cohesion: 0.11
Nodes (18): ../data/firebase_push_token_source.dart, ../data/firestore_fcm_token_repository.dart, fcmTokenRepositoryProvider, pushRegistrationServiceProvider, fcmTokenRepository, pushArrivals, pushRegistrationService, pushTokenSource (+10 more)

### Community 73 - "App Config Function"
Cohesion: 0.16
Nodes (14): isVersionCode(), NOTES_MAX, optionalText(), setAppConfig(), VERSION_NAME_MAX, webLink(), FUNCTION_NAMES, functionNamed() (+6 more)

### Community 74 - "Mobile Pubspec Deps"
Cohesion: 0.11
Nodes (19): iOS Launch Screen Assets, Flutter gen-l10n Config (AppLocalizations, app_en.arb), cloud_firestore, cloud_functions (deleteAccount), drift, fake_cloud_firestore, firebase_auth, firebase_messaging (FCM) (+11 more)

### Community 75 - "Release & Deploy Runbook"
Cohesion: 0.12
Nodes (18): scripts/build-release-apk.sh, config/app version doc (npm run release, --min), Deploy runbook — signed release, Path B: Play Store internal testing (signed AAB), Register release SHA-1/SHA-256 with Firebase, Upload keystore (the app's identity without Play App Signing), Debug SHA-1 per machine (Google Sign-In fails silently), scripts/demo-mobile.sh (emulator/usb/ios/iphone) (+10 more)

### Community 76 - "shadcn components.json"
Cohesion: 0.11
Nodes (17): aliases, components, hooks, lib, ui, utils, iconLibrary, rsc (+9 more)

### Community 77 - "Header Widgets & Bell"
Cohesion: 0.18
Nodes (12): IconBrandMark(), LanguageSwitcher(), ICONS, NotificationBell(), readSeen(), TITLE_KEYS, SiteControls(), OPTIONS (+4 more)

### Community 78 - "App Update Providers"
Cohesion: 0.17
Nodes (16): appConfigRepositoryProvider, ../data/package_info_installed_version.dart, appConfig, appConfigRepository, AppUpdateController, appUpdateControllerProvider, installedVersion, updateDismissalStore (+8 more)

### Community 79 - "App Shell & Offline"
Cohesion: 0.12
Nodes (16): AsyncValue, core/network/connectivity_providers.dart, core/widgets/offline_banner.dart, Family, ../features/auth/application/auth_providers.dart, features/donation/application/donation_providers.dart, features/match/application/match_providers.dart, ../features/match/presentation/match_detail_screen.dart (+8 more)

### Community 80 - "Khmer Copy & Districts"
Cohesion: 0.18
Nodes (17): DEC-005 All 14 districts seeded; 1213/1214 provisional, FR-GLOBAL-001 Khmer and English localization, Khmer copy review (DEC-019 strings), Blood bank term choice (ផ្នែកផ្តល់ឈាម), Phnom Penh districts reference (14 khan), Phnom Penh hospitals pilot reference (5), National Blood Transfusion Center (NBTC), Cambodia donation reality research (2026-09) (+9 more)

### Community 81 - "Telegram Sign-In (Dropped)"
Cohesion: 0.15
Nodes (17): PRD FR-01 Authentication (Google Sign-In), SEC-REVIEW-002 Telegram Sign-In, FR-AUTH-004 Additional sign-in providers, TelegramAuthController, TelegramAuthService, TelegramRateLimiter, ADMIN = custom claim AND admins/{uid} record, E1 Client-chosen role (+9 more)

### Community 82 - "Donation Providers"
Cohesion: 0.14
Nodes (14): ../../../core/firebase/firestore_providers.dart, ../data/firestore_donation_repository.dart, ../data/firestore_report_repository.dart, donation_service.dart, donationRepositoryProvider, myDonationsControllerProvider, donationRepository, donationService (+6 more)

### Community 83 - "ADR 0010 Portal Functions"
Cohesion: 0.18
Nodes (16): POST /api/functions/{name} callable protocol, createRequest handler (replaces onRequestCreated), deleteAccount handler, ADR 0010: Portal's server runs the functions; Cloud Functions and Blaze go, invoke.ts verifies Firebase ID token with Admin SDK, matchedAt claimed in a transaction (at-most-once alerts), _outbox push fallback on demo/emulator, Portal on the app's critical path (Vercel Hobby, no SLA) (+8 more)

### Community 84 - "Match Sync DAO"
Cohesion: 0.20
Nodes (11): ../data/match_sync_dao.dart, ../domain/match.dart, ../domain/match_repository.dart, ../domain/match_response_type.dart, ../domain/respond_result.dart, match_sync_dao.dart, MatchService, MatchSyncService (+3 more)

### Community 85 - "Book Deps"
Cohesion: 0.13
Nodes (15): dependencies, clsx, @docusaurus/core, @docusaurus/preset-classic, @mdx-js/react, prism-react-renderer, react, react-dom (+7 more)

### Community 86 - "Push Registration"
Cohesion: 0.13
Nodes (10): ../domain/fcm_token_repository.dart, ../domain/push_arrival.dart, ../domain/push_token_source.dart, PushRegistrationService, firebasePushArrivals, FirebasePushTokenSource, PushArrival, PushTokenSource (+2 more)

### Community 87 - "SEO & Sitemap"
Cohesion: 0.27
Nodes (11): DownloadPage(), robots(), sitemap(), INDEXED_PATHS, jsonLd(), localizedAlternates(), mobileAppJsonLd(), OG_IMAGE (+3 more)

### Community 88 - "About Providers"
Cohesion: 0.14
Nodes (11): ../../../core/config/env.dart, ../../../core/settings/locale_controller.dart, ../domain/installed_version.dart, AppVersion, PackageInfoInstalledVersion, InstalledVersion, _FakeInstalledVersion, _FakeInstalledVersion (+3 more)

### Community 89 - "M4 Matching Spec"
Cohesion: 0.22
Nodes (14): M4 Build Spec: Request, matching, alert, alertedCount = matches written, not pushes delivered, Compatibility direction rule, FCM donor alert push (FR-NOTIFY-001), GET /requests/{id} visibility (404 not 403), Hospital seed V7 (5 Phnom Penh hospitals), least() NULL-skip bug, Matching SQL query (haversine, NULLS LAST, LIMIT 25) (+6 more)

### Community 90 - "Firestore Data Model"
Cohesion: 0.18
Nodes (14): confirmDonation handler, Firestore collection requests/{id}/acceptedDonors/{boardId}, Firestore collection admins/{uid}, boardId = sha256(requestId:donorUid) first 24 hex, Firestore data model, Firestore collection donations/{donationId}, Firestore collection donors/{uid}, isAdmin(): ADMIN claim AND admins/{uid} record (+6 more)

### Community 91 - "Excel Export"
Cohesion: 0.24
Nodes (11): ExportExcelButton(), buildXlsx(), columnName(), crc32(), CRC_TABLE, encoder, Sheet, sheetNames() (+3 more)

### Community 92 - "confirmDonation Function"
Cohesion: 0.23
Nodes (10): addDays(), confirmDonation(), dateToTimestamp(), ADR-0009, phnomPenhToday(), isAdmin(), admin, confirm() (+2 more)

### Community 93 - "Drift DAO Layer"
Cohesion: 0.15
Nodes (11): @DriftAccessor, @DriftDatabase, ../../../core/database/app_database.dart, DatabaseAccessor, _$MatchSyncDaoMixin, AppDatabase, LocalDataEraser, MatchSyncDao (+3 more)

### Community 94 - "App Config Repository"
Cohesion: 0.21
Nodes (11): app_config.dart, FirestoreAppConfigRepository, AppConfigRepository, UnconfiguredAppConfigRepository, AppUpdate, appUpdateFor, UpdateAvailable, UpdateRequired (+3 more)

### Community 95 - "Notifications Screen"
Cohesion: 0.18
Nodes (11): ../application/inbox_providers.dart, ../../../core/time/relative_time.dart, ../../match/presentation/match_detail_screen.dart, NotificationBell, _Message, NotificationsScreen, _NotificationsScreenState, _NotificationTile (+3 more)

### Community 96 - "Admin Seed & Accounts"
Cohesion: 0.17
Nodes (11): RFC-2606, ADMIN, auth, db, email, googleEmail, ADR-0009, projectFlag (+3 more)

### Community 97 - "Production Checklist & Spark"
Cohesion: 0.17
Nodes (13): FIREBASE_SERVICE_ACCOUNT env var on Vercel, Spark plan, no billing card, Path A: sideloaded APK until 500 users (K.O.S.I.G.N store / GitHub Releases), $0/month target until 500 users, Production checklist — real Firebase project, Part A: Firebase project on Spark, asia-southeast1, Part B: deploy rules and indexes, Part C: seed data and admin account (+5 more)

### Community 98 - "Postgres ERD (Legacy)"
Cohesion: 0.29
Nodes (13): blood_compatibility table, blood_requests table, Database-enforced constraints (CHECK, UNIQUE, FK), districts table, Data Model — ERD (PostgreSQL, superseded), donations table, donations is the sole source of truth for eligibility, donor_profiles table (+5 more)

### Community 99 - "Week 3 Course Slides"
Cohesion: 0.27
Nodes (13): Dependency Rule (presentation -> application -> domain <- data), Exercise E03.1 Refactor FieldLog to Layered Architecture, Week 3 Errata, FakeProfileRepository, FieldLog Capstone (Track A), Four-Layer Architecture (presentation/application/domain/data), Profile Immutable Entity (value equality), Abstract Repository Contract (ProfileRepository) (+5 more)

### Community 100 - "Auth Service Domain"
Cohesion: 0.24
Nodes (9): dart:convert, ../domain/auth_repository.dart, ../domain/auth_session.dart, ../domain/auth_user.dart, ../domain/facebook_credentials.dart, ../domain/session_store.dart, ../domain/user_role.dart, AuthService (+1 more)

### Community 101 - "Firestore Rules Tests"
Cohesion: 0.23
Nodes (9): admin(), as(), contact, hospitalClaim(), ADR-0009, ADR-0010, newRequest(), seed() (+1 more)

### Community 102 - "respondToMatch Function"
Cohesion: 0.18
Nodes (10): answer(), respondToMatch(), accepted, answer(), ADR-0010, messaging, quiet, respond() (+2 more)

### Community 103 - "Bar Chart"
Cohesion: 0.21
Nodes (9): BarChart(), niceScale(), PAD, Row, Series, ChartCard(), ExportImageButton(), LegendItem (+1 more)

### Community 104 - "Credential Adapters"
Cohesion: 0.17
Nodes (10): FirebaseFacebookCredentials, FirebaseGoogleCredentials, FacebookCredentials, GoogleCredentials, _FakeFacebookCredentials, _FakeGoogleCredentials, _GatedGoogleCredentials, FakeFacebookCredentials (+2 more)

### Community 105 - "Match Detail Screen"
Cohesion: 0.22
Nodes (10): ../application/match_providers.dart, _acceptStyle, MatchDetailScreen, _MatchDetailScreenState, _RespondSheet, _RespondSheetState, _ReviewedBadge, _SelfCheckWarning (+2 more)

### Community 106 - "Project Plan & Milestones"
Cohesion: 0.24
Nodes (11): LifeLink KH project plan (CLAUDE.md), Course milestones M1-M8, Why mobile: push + GPS a website cannot do, Signed APK on GitHub Releases + SHA-256, geolocator GPS, no map widget, DEC-001, DEC-006 iOS build-only target, DEC-008 M8 demo scenario (+3 more)

### Community 107 - "Metrics Script"
Cohesion: 0.18
Nodes (8): db, donorTimes, firstAccepted, live, ADR-0009, projectFlag, reviews, waits

### Community 108 - "Release Script"
Cohesion: 0.18
Nodes (8): downloadUrl, minArg, notesEn, notesKm, privacyUrl, ref, versionCode, versionName

### Community 109 - "Demo Seed"
Cohesion: 0.20
Nodes (10): db, DOUN_PENH, messaging, ADR-0003, ADR-0009, ADR-0010, now(), post() (+2 more)

### Community 110 - "Frontend Package Meta"
Cohesion: 0.18
Nodes (10): engines, node, name, overrides, brace-expansion@<1.1.21, brace-expansion@>=5.0.0 <5.0.12, jwks-rsa, uuid@<11.1.1 (+2 more)

### Community 111 - "Week 4 Riverpod Slides"
Cohesion: 0.22
Nodes (11): Exercise E04.1 Riverpod-managed Profile state, Week 4 Errata (fieldlog_flutter_week4 divergences), ProviderContainer Testing, ProviderScope, ref.read vs ref.watch, Riverpod State Management, riverpod_generator Code Generation, Week 4 QCM Chapter Exam (+3 more)

### Community 112 - "Notification Inbox Repo"
Cohesion: 0.22
Nodes (8): app_notification.dart, ../domain/app_notification.dart, ../domain/notification_inbox_repository.dart, FirestoreNotificationInboxRepository, notificationFrom, EmptyNotificationInbox, NotificationInboxRepository, _FakeInbox

### Community 113 - "Auth Repository"
Cohesion: 0.20
Nodes (7): auth_session.dart, FirebaseAuthRepository, AuthRepository, AuthUser, _FakeAuthRepository, FakeAuthRepository, user_role.dart

### Community 114 - "Book Package Meta"
Cohesion: 0.20
Nodes (9): description, engines, node, name, overrides, serialize-javascript, uuid@<11.1.1, private (+1 more)

### Community 115 - "Decisions Generator"
Cohesion: 0.22
Nodes (7): a, book, cell(), d, docsRoot, here, table()

### Community 116 - "ADR 0008 Notify Cap"
Cohesion: 0.22
Nodes (10): Deterministic ranking: distance asc NULLS LAST, then donor id, ADR 0008: At most 25 donors notified per request, Max notified cap = 25 (MATCHING_MAX_NOTIFIED), O-negative donor notification fatigue risk, Only notified donors get a request_matches row, PRD metric: >=70% requests accepted within 60 min, units_needed does not change the cap, Matching invariants carried over (no self-match, 56-day cooldown, cap 25, one response) (+2 more)

### Community 117 - "Frontend Scripts"
Cohesion: 0.20
Nodes (10): scripts, build, dev, format, format:check, lint, start, test (+2 more)

### Community 118 - "Locale Layout"
Cohesion: 0.27
Nodes (7): generateMetadata(), inter, kantumruyPro, LocaleLayout(), SiteFooter(), ThemeProvider(), siteJsonLd()

### Community 119 - "Request Lifecycle Tests"
Cohesion: 0.22
Nodes (6): handleRequestCreated(), handle(), intake(), messaging, NOW, quiet

### Community 120 - "Connectivity Providers"
Cohesion: 0.20
Nodes (9): isOfflineProvider, isOffline, _noInterface, package:connectivity_plus/connectivity_plus.dart, StreamProviderRef, isOfflineProvider, IsOfflineRef, InboxRef (+1 more)

### Community 121 - "App Theme"
Cohesion: 0.25
Nodes (7): @immutable, AppTheme, AppTokens, testExecutable, package:flutter/cupertino.dart, package:google_fonts/google_fonts.dart, ThemeExtension

### Community 122 - "Donor Domain Models"
Cohesion: 0.25
Nodes (6): blood_type.dart, donor_sex.dart, eligibility.dart, DonorProfile, DonorProfileDraft, Eligibility

### Community 123 - "Book Browserslist"
Cohesion: 0.22
Nodes (9): browserslist, development, production, >0.5%, last 3 chrome version, last 3 firefox version, last 5 safari version, not dead (+1 more)

### Community 124 - "Book Dev Deps"
Cohesion: 0.22
Nodes (9): devDependencies, @docusaurus/module-type-aliases, @docusaurus/tsconfig, @docusaurus/types, typescript, typescript, @docusaurus/module-type-aliases, @docusaurus/tsconfig (+1 more)

### Community 125 - "ADR 0007 Session Lifetime"
Cohesion: 0.28
Nodes (9): DELETE /auth/fcm-token endpoint for sign-out, ADR 0007: Session JWT lifetime and expiry, No server-side revocation; one-hour compromise window accepted, One-hour session JWT lifetime (JWT_LIFETIME PT1H), Rejected: own refresh-token table with rotation, JWT in platform secure storage (Keychain/Keystore), Silent re-authentication on 401 (getIdToken forceRefresh + POST /auth/google, retry once), Single-flight re-auth: concurrent 401s collapse to one sign-in (+1 more)

### Community 126 - "Donor Repository"
Cohesion: 0.25
Nodes (7): district.dart, donor_profile.dart, donor_profile_draft.dart, FirestoreDonorRepository, DonorRepository, _FakeDonorRepository, FakeDonorRepository

### Community 127 - "Book Scripts"
Cohesion: 0.25
Nodes (8): scripts, build, clear, decisions, serve, start, start:en, write-translations

### Community 128 - "Book TS Config"
Cohesion: 0.25
Nodes (7): compilerOptions, baseUrl, exclude, extends, build, .docusaurus, @docusaurus/tsconfig

### Community 129 - "i18n Routing"
Cohesion: 0.39
Nodes (4): { Link, usePathname, useRouter }, Locale, routing, config

### Community 130 - "Week 5 Async Slides"
Cohesion: 0.32
Nodes (8): Notifier<T>, AsyncNotifier<T>, AsyncValue<T> Sealed Union, Exercise E05.1 AsyncNotifier with Four States, Four-State Framework (Loading/Data/Error/Empty), Team Milestone M2 Wireframes & Feature Scope, Skeleton Loading (not spinners), Week 5 Slides: AsyncNotifier & AsyncValue

### Community 131 - "Week 6 Sealed Errors"
Cohesion: 0.36
Nodes (8): Silent-Failure Anti-Pattern, Exercise E06.1 Sealed Errors and Result Types, Either<L, R> (fpdart alternative), Sealed Domain Failure, Result<T> = Success<T> | Failed<T>, Dart 3 Sealed Classes & Exhaustive Pattern Matching, Domain Failures vs Programmer Errors, Week 6 Slides: Errors as Values

### Community 132 - "Env & Crash Handling"
Cohesion: 0.25
Nodes (6): Env, buildErrorWidget, installCrashHandlers, package:flutter/foundation.dart, package:flutter/widgets.dart, ../widgets/screen_failure.dart

### Community 133 - "Intro Screen"
Cohesion: 0.33
Nodes (6): ../../auth/presentation/sign_in_screen.dart, ../core/settings/onboarding_controller.dart, ../../../core/widgets/brand_backdrop.dart, IntroScreen, _IntroScreenState, _Slide

### Community 134 - "Android MainActivity"
Cohesion: 0.38
Nodes (3): Bundle, FlutterActivity, MainActivity

### Community 135 - "Profile Avatar Painter"
Cohesion: 0.29
Nodes (6): CustomPainter, dart:math, AvatarPainter, _Look, ProfileAvatar, _TowersPainter

### Community 136 - "Drift Data Classes"
Cohesion: 0.38
Nodes (7): DataClass, Insertable, UpdateCompanion, PendingSyncCompanion, PendingSyncData, RequestMatchRow, RequestMatchRowsCompanion

### Community 137 - "reviewRequest Function"
Cohesion: 0.33
Nodes (5): reviewRequest(), admin, messaging, quiet, review()

### Community 138 - "Match Domain"
Cohesion: 0.29
Nodes (5): match.dart, match_response_type.dart, RespondResult, ../../request/domain/requester_contact.dart, respond_result.dart

### Community 139 - "Base Seed"
Cohesion: 0.33
Nodes (5): batch, db, { districts, hospitals }, ADR-0009, projectFlag

### Community 140 - "Next Config"
Cohesion: 0.33
Nodes (5): nextConfig, SECURITY_HEADERS, ADR-0009, ADR-0010, withNextIntl

### Community 141 - "Prettier Config"
Cohesion: 0.33
Nodes (5): printWidth, semi, singleQuote, tabWidth, trailingComma

### Community 142 - "Link Opener"
Cohesion: 0.40
Nodes (5): LinkOpener, UrlLauncherLinkOpener, _RecordingLinkOpener, _RecordingLinkOpener, package:url_launcher/url_launcher.dart

### Community 143 - "Roles & Templates"
Cohesion: 0.40
Nodes (5): Roles and Flows, CR-MAPI change requests, Security flow (R5): threat model + review before merge, Security Review Template, Threat Model Template

### Community 144 - "ESLint Config"
Cohesion: 0.40
Nodes (4): compat, __dirname, eslintConfig, __filename

### Community 145 - "Invoke Tests"
Cohesion: 0.50
Nodes (4): draft, ADR-0010, signUp(), signUpOnly()

### Community 146 - "Result Type"
Cohesion: 0.80
Nodes (4): Failed, Result, Success, T

### Community 147 - "Geohash"
Cohesion: 0.40
Nodes (4): donorCoordinateDecimals, donorGeohashPrecision, encodeGeohash, roundDonorCoordinate

### Community 148 - "Report Repository"
Cohesion: 0.40
Nodes (4): FirestoreReportRepository, ReportRepository, _FakeReports, report_reason.dart

### Community 149 - "Secrets History Scan"
Cohesion: 0.50
Nodes (4): SEC-REVIEW-006 History Secrets Scan, C1 restrict Firebase client API keys, gitleaks full-history scan, .gitleaksignore fingerprints

### Community 150 - "verify.mjs"
Cohesion: 0.50
Nodes (3): db, districts, orphans

### Community 151 - "vercel.json"
Cohesion: 0.50
Nodes (3): regions, $schema, sin1

### Community 152 - "app_config.dart"
Cohesion: 0.50
Nodes (3): AppConfig, ReleaseNotes, webLinkFrom

### Community 155 - "frontend AGENTS.md: Next.js agent rules"
Cohesion: 0.67
Nodes (3): frontend AGENTS.md: Next.js agent rules, This is NOT the Next.js you know — read node_modules/next/dist/docs, frontend CLAUDE.md (@AGENTS.md)

### Community 158 - "PendingSync"
Cohesion: 0.67
Nodes (3): PendingSync, RequestMatchRows, Table

## Ambiguous Edges - Review These
- `DEC-019 Cambodian/NBTC medical practice, 90/120-day cooldown` → `Feature 1: Donor register + 56-day eligibility`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to
- `Eligibility computed on read (56-day)` → `90/120-day cooldown by sex`  [AMBIGUOUS]
  docs/fullstack/specs/features/donor-profile.md · relation: conceptually_related_to

## Knowledge Gaps
- **875 isolated node(s):** `config`, `name`, `version`, `private`, `description` (+870 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **30 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `DEC-019 Cambodian/NBTC medical practice, 90/120-day cooldown` and `Feature 1: Donor register + 56-day eligibility`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Eligibility computed on read (56-day)` and `90/120-day cooldown by sex`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Locale` connect `i18n Routing` to `Portal API Route Handlers`, `App Shell & Offline`, `Locale Layout`, `SEO & Sitemap`?**
  _High betweenness centrality (0.307) - this node is a cross-community bridge._
- **Why does `Cambodia donation reality research (2026-09)` connect `Khmer Copy & Districts` to `Briefs & Changelog`, `User Guides & Features`, `Early Decisions & PRD Scope`, `Firebase Flow & Demo Runbook`, `Rulebook & Core Rules`, `NBTC Letter & Eligibility`, `M4 Matching Spec`, `Donor Domain Models`, `Matching & Cooldown`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._
- **Why does `HttpsError` connect `createRequest Function` to `Portal API Route Handlers`, `Portal Actions & API Client`, `App Config Function`, `FCM Push & Inbox`, `confirmDonation Function`, `deleteAccount Function`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **What connects `config`, `name`, `version` to the rest of the system?**
  _875 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Portal API Route Handlers` be split into smaller, more focused modules?**
  _Cohesion score 0.05548654244306418 - nodes in this community are weakly interconnected._