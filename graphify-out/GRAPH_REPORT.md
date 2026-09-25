# Graph Report - .  (2026-09-25)

## Corpus Check
- Large corpus: 649 files · ~495,065 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 3271 nodes · 7258 edges · 215 communities (145 shown, 70 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 939 edges (avg confidence: 0.81)
- Token cost: 1,178,057 input · 0 output

## Community Hubs (Navigation)
- FR Docs & Rulebook
- Donor Profile API
- Auth Controller Endpoints
- API Errors & DTOs
- Drift Generated Schema
- Flutter Widget Tests
- Mobile Error & Result Types
- Portal Bootstrap & Demo Decisions
- Eligibility Calculator
- Blood Request Entity
- API Contract Change Requests
- Admin Staff Service
- Auth Service Tests
- Board & Donation Services
- Riverpod Providers Core
- Auth Security Reviews
- Dio Failure Mapping
- Mobile Auth Repositories
- Riverpod Repo Wiring
- Portal Staff Actions
- Mobile Auth Service
- Donation Repository Queries
- Prototypes & Data Tables
- Mobile DB & Location
- District & Public Donor
- Match Controller
- Donation History UI
- Admin Controller
- Defense Deck v2 Builder
- Portal Landing & Sign-In
- Backend Config & CI
- Mobile Assets & Config
- Donor Setup UI
- Scope Cut & Risks
- Portal Confirm Donation
- UI Screenshots & Goldens
- PRD & Architecture ADRs
- App Icon Family
- Capybara Brief & Setup
- Hospital Entity
- Project Plan & Milestones
- TS Config
- Mobile Service Tests
- Match Respond Flow
- Schema Integration Tests
- Mobile Donor Service
- Defense Deck v1 Builder
- Request Form Screens
- Backend Auth Service
- Global Exception Handler
- Telegram Auth Challenge
- Locale Store
- Telegram Challenge Repo
- Push Registration
- District Controller
- App Router & Theme
- Request Flow Integration Test
- Firebase Token Verifier
- Public Board Service
- QA Bugs & Build Traps
- Health Check Mobile
- FCM Token Providers
- Donation Entity
- Donation Controller
- Donation History Tests
- Dead Token Cleanup
- Portal Password Bootstrap
- Portal Change Password
- App Entry & Onboarding Store
- Telegram Auth Service
- iOS Runner
- LifeLink App Shell
- Portal Requests Page
- User Account Model
- JWT Service
- Acceptance Notifier
- Mobile Request Domain
- Telegram DTOs
- Telegram Bot Client
- Mobile API Client
- Mobile Match Domain
- Health & Swagger
- Mobile Failure Mapper
- Telegram Webhook Tests
- Urgency & Picker
- Frontend Dev Dependencies
- Portal Layout & i18n
- Onboarding Controller
- Sign-In Screen
- Security Config
- Request Alert Notifier
- Mobile Session Store
- Mobile Donation Providers
- Frontend Package Scripts
- Match Sync DAO
- JWT Auth Filter
- District Controller Tests
- Health Service Tests
- Portal Time Helpers
- Android 12 Splash
- Android Splash Screens
- Match Repositories
- Maven Wrapper
- Data Model Tables
- Donor Registration Test
- Auditable Base Entity
- Health Controller Tests
- Public Board Contract
- dependencies
- board.ts
- DioRequestRepository
- district.dart
- HospitalController.java
- DataClass
- AuthController.java
- Foundation Spec: Spring Boot API + Postg
- iOS launch image
- JacksonConfig.java
- OpenApiConfig.java
- TimeConfig.java
- TelegramUpdate.java
- blood_type.dart
- .prettierrc.json
- LifeLink app icon background
- LifeLink app icon foreground (blood drop
- BUG-BUILD-003: Testcontainers skipped sc
- CR-MAPI-001: districtName carries both l
- match_detail_screen.dart (PENDING badge)
- CR-SEC Change Request Template
- eslint.config.mjs
- Launcher background
- Week 1 Slides: Setup & Flutter Project A
- b64()
- auth_token_gateway.dart
- LifelinkApiApplication.java
- POST /auth/telegram/start
- GET/POST /admin/staff
- auth_user.dart
- validate.sh
- Bug Report Template
- FlutterActivity
- next.config.ts
- session.test.ts
- iOS launch background
- mint-portal-jwt.java
- Adaptive icon background
- Adaptive icon foreground
- Mobile Donation History (Khmer)
- Swagger API Console
- POST /auth/portal/login (openapi)
- Deny-by-default SecurityConfig chain
- eslint-config-next
- @eslint/eslintrc
- jsdom
- @testing-library/dom
- @testing-library/jest-dom
- @testing-library/react
- @types/node
- @types/react-dom
- vitest
- postcss.config.mjs
- File icon SVG
- Globe icon SVG
- Next.js logo SVG
- Vercel logo SVG
- Window icon SVG
- pre-commit
- App icon (mipmap-hdpi)
- Splash screen dark
- Splash screen light
- env.dart
- telegram_start_session.dart
- user_role.dart
- donation.dart
- blood_type.dart
- district.dart
- eligibility.dart
- health_status.dart
- match_response_type.dart
- hospital.dart
- request_status.dart
- requester_contact.dart
- Mobile Model Choice (R3): Flutter native
- Capybara Stack (R3): Spring Boot+Postgre
- POST/DELETE /auth/fcm-token
- GET /donations/me
- GET /hospitals
- GET /matches/me
- GET /requests/{id}
- POST /requests/{id}/cancel
- GET /requests/me
- POST /admin/staff/accounts
- V4__hospitals_district.sql
- UUID primary keys rationale (anti-enumer
- Mobile Role Scope (Flutter)
- Withdrawn acceptance brief gap (due befo
- ADR Template
- blood_compatibility reference table
- telegram_auth_challenges table
- DevTools Options Config
- BloodRequest
- District
- DonationRepository
- Hospital
- requestDetailProvider
- Table
- kh.lifelink:lifelink-api

## God Nodes (most connected - your core abstractions)
1. `User` - 70 edges
2. `docs/scope.md — 19 FRs requested, 8 built, 8 deferred` - 49 edges
3. `Hospital` - 45 edges
4. `ApiException` - 40 edges
5. `BloodRequest` - 40 edges
6. `DonorProfile` - 39 edges
7. `CLAUDE.md — LifeLink KH Project Plan` - 38 edges
8. `RequestMatch` - 37 edges
9. `Feature Registry (FR) Index` - 36 edges
10. `District` - 34 edges

## Surprising Connections (you probably didn't know these)
- `PRD (docs/po/prd.md)` --implements--> `Requirement: One product idea — problem, target user, three features`  [INFERRED]
  docs/po/briefs/README.md → Cross-Platform-Project-task.jpg
- `docs/po/presentations/run-of-show.md` --semantically_similar_to--> `FR-NOTIFY-003: Requester acceptance push`  [INFERRED] [semantically similar]
  README.md → docs/po/briefs/BRIEF-NOTIFY-001-requester-acceptance-push.md
- `CLAUDE.md — LifeLink KH Project Plan` --references--> `Cheat sheet (rulebook R1–R8)`  [EXTRACTED]
  Cross-Platform-Project-task.jpg → docs/po/briefs/README.md
- `FR-PORTAL-001 — Hospital request management (web)` --cites--> `CLAUDE.md — LifeLink KH Project Plan`  [EXTRACTED]
  docs/po/features/FR-PORTAL-001-hospital-request-management.md → Cross-Platform-Project-task.jpg
- `CLAUDE.md — LifeLink KH Project Plan` --references--> `Capybara Setup — LifeLink KH`  [EXTRACTED]
  Cross-Platform-Project-task.jpg → .capybara/setup.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **PO artifact pipeline: brief → prototype → FR → changelog** — docs_po_briefs_readme_brief, docs_po_prototypes_readme_prototype, docs_po_features__template, docs_po_briefs_readme_po_flow, docs_po_changelog [EXTRACTED 1.00]
- **Urgent request end-to-end flow (post → match → push → accept → confirm)** — docs_po_features_fr_request_001_create_urgent_request, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_notify_001_request_push_alert, docs_po_features_fr_request_002_respond_accept_decline, docs_po_features_fr_portal_001_hospital_request_management, docs_po_features_fr_donation_001_donation_history [EXTRACTED 1.00]
- **R5 Security Overlay Flow — triggers, checklist, threat model, review note, CR-SEC channel** — docs_security_threat_models__template_threat_model, docs_security_reviews__template_security_review, docs_security_change_requests_cr_sec_index_cr_sec_registry, docs_security_claude_security_overlay_scope [EXTRACTED 1.00]
- **DEC-001/002/003 reshape M4 so its own acceptance criteria are satisfiable** — docs_decisions_dec_001, docs_decisions_dec_002, docs_decisions_dec_003, claude_m4 [EXTRACTED 0.90]
- **Portal authentication evolution: public board, staff password login, unseeded env-only passwords** — docs_decisions_dec_009, docs_decisions_dec_010, docs_decisions_dec_013 [INFERRED 0.85]
- **Demo-first delivery strategy: local demo as deliverable, store release resequenced after** — docs_decisions_dec_012, docs_demo_runbook, docs_po_demo_script, docs_tech_lead_deploy_runbook [EXTRACTED 0.90]
- **District/Hospital name dual-label {km,en} pattern across contracts** — docs_fullstack_api_contract_mobile_change_requests_cr_mapi_001, docs_fullstack_api_contract_mobile_openapi_districtname_schema, docs_fullstack_api_contract_web_openapi_publicdonor_schema, docs_fullstack_api_contract_web_openapi_accepteddonor_schema [INFERRED 0.85]
- **Accept-flow contact gap: CR-MAPI-003, V5 migration, and ADR 0002's phone drop** — docs_fullstack_api_contract_mobile_change_requests_cr_mapi_003, docs_fullstack_specs_features_request_and_matching_v5_request_contact_sql, tech_lead_adr_0002_auth_google_sign_in, docs_fullstack_api_contract_mobile_openapi_requestercontact_schema [INFERRED 0.85]
- **Offline-first accept/decline sync slice (Drift + idempotency + server-wins)** — docs_mobile_local_db_and_sync_match_sync_service, docs_mobile_local_db_and_sync_match_sync_dao, docs_mobile_local_db_and_sync_offline_first_match_repository, docs_mobile_local_db_and_sync_conflict_rules, docs_fullstack_api_contract_mobile_contract_idempotency_key [INFERRED 0.80]
- **Features deferred by the DEC-004 scope cut** — docs_po_features_fr_match_002_zero_match_fallback, docs_po_features_fr_notify_002_eligibility_reminder, docs_po_features_fr_portal_002_admin_dashboard, docs_po_features_fr_request_003_duplicate_request_warning, docs_po_features_fr_request_004_withdraw_acceptance, docs_po_features_fr_request_005_request_expiry, docs_po_features_fr_security_001_account_data_deletion, docs_po_features_fr_global_002_metrics_instrumentation [EXTRACTED 1.00]
- **Verified-Google-identity account ecosystem (sign-in, profile, staff provisioning)** — docs_po_features_fr_auth_003_google_sign_in, docs_po_features_fr_auth_004_additional_sign_in_providers, docs_po_features_fr_donor_001_donor_profile, docs_po_features_fr_portal_003_staff_provisioning [INFERRED 0.85]
- **M4 core loop: eligibility computation, matching, and push alert resequenced together** — docs_po_features_fr_donor_002_eligibility_check, docs_po_features_fr_match_001_donor_matching, docs_po_features_fr_notify_001_request_push_alert [EXTRACTED 1.00]
- **M2 infra bug trio found and closed together during test-strategy verification** — docs_qa_bugs_bug_infra_001_postgres_port_5432_occupied, docs_qa_bugs_bug_web_002_next_standalone_binds_container_id, docs_qa_bugs_bug_build_003_testcontainers_skips_with_docker_running, docs_qa_test_strategy [EXTRACTED 0.90]
- **One-directional donor/requester contact-reveal design across mobile and web** — docs_po_prototypes_mobile_notify_donor_alert_readme, docs_po_prototypes_mobile_request_responders_list_readme, docs_po_prototypes_web_portal_open_requests_readme [INFERRED 0.80]
- **Phnom Penh district/hospital reference data feeding donor location capture** — docs_po_reference_phnom_penh_districts, docs_po_reference_phnom_penh_hospitals, docs_po_prototypes_mobile_donor_profile_setup_readme [INFERRED 0.75]
- **R5 Security Gate: Threat Model + Review for Auth Changes** — docs_roles_and_flows_r5_security_gate, docs_security_threat_models_tm_auth_001_google_sign_in, docs_security_reviews_sec_review_001_google_sign_in, docs_security_security_checklist [INFERRED 0.80]
- **Telegram Fallback Auth: ADR to Threat Model to Security Review** — docs_tech_lead_adr_0002_auth_google_sign_in, docs_security_threat_models_tm_auth_002_telegram_sign_in, docs_security_reviews_sec_review_002_telegram_sign_in [INFERRED 0.85]
- **FR-MATCH-001's Three Blockers Resolved by ADRs 0003, 0004, 0008** — docs_tech_lead_adr_0003_donor_location_precision, docs_tech_lead_adr_0004_abo_rh_compatibility_lookup_table, docs_tech_lead_adr_0008_max_notified_donor_count, docs_scope_fr_match_001_matching [INFERRED 0.85]
- **Course-Taught Layered Architecture & Service Pattern Implemented in LifeLink Mobile App** — mobile_docslesson_003_layered_architecture, mobile_docslesson_003_service_pattern, mobile_readme_architecture_layers [INFERRED 0.85]
- **Riverpod State-Management Progression (Weeks 4-6) Realized in App Dependencies** — mobile_docslesson_004_riverpod_di, mobile_docslesson_005_asyncnotifier_asyncvalue, mobile_docslesson_006_result_failure, mobile_pubspec_riverpod_version_choice [INFERRED 0.80]
- **Firebase/Google Sign-In Credential Setup Across Runbooks and Mobile App** — docs_tech_lead_local_development_firebase_setup, docs_tech_lead_deploy_runbook_play_app_signing, mobile_readme [INFERRED 0.80]
- **Donor Home Golden Test Failure Set (master/test/diffs)** — mobile_test_failures_donor_home_masterimage_image, mobile_test_failures_donor_home_testimage_image, mobile_test_failures_donor_home_isolateddiff_image, mobile_test_failures_donor_home_maskeddiff_image [EXTRACTED 1.00]
- **Requester Home Golden Test Failure Set (master/test/diffs)** — mobile_test_failures_requester_home_masterimage_image, mobile_test_failures_requester_home_testimage_image, mobile_test_failures_requester_home_isolateddiff_image, mobile_test_failures_requester_home_maskeddiff_image [EXTRACTED 1.00]
- **Khmer/English Screen Variant Group** — docs_assets_screens_board_public_en_screen, docs_assets_screens_board_public_km_screen, mobile_test_goldens_donation_guide_en_golden, mobile_test_goldens_donation_guide_km_golden [INFERRED 0.85]
- **Frontend SVG icon assets** — frontend_public_file_image, frontend_public_globe_image, frontend_public_next_image, frontend_public_vercel_image, frontend_public_window_image [INFERRED 0.85]
- **App icon background density variants (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)** — mobile_android_app_src_main_res_drawable_hdpi_ic_launcher_background_image, mobile_android_app_src_main_res_drawable_mdpi_ic_launcher_background_image, mobile_android_app_src_main_res_drawable_xhdpi_ic_launcher_background_image, mobile_android_app_src_main_res_drawable_xxhdpi_ic_launcher_background_image, mobile_android_app_src_main_res_drawable_xxxhdpi_ic_launcher_background_image [INFERRED 0.95]
- **App icon foreground density variants (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)** — mobile_android_app_src_main_res_drawable_hdpi_ic_launcher_foreground_image, mobile_android_app_src_main_res_drawable_mdpi_ic_launcher_foreground_image, mobile_android_app_src_main_res_drawable_xhdpi_ic_launcher_foreground_image, mobile_android_app_src_main_res_drawable_xxhdpi_ic_launcher_foreground_image, mobile_android_app_src_main_res_drawable_xxxhdpi_ic_launcher_foreground_image [INFERRED 0.95]
- **Splash screen light variants (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)** — mobile_android_app_src_main_res_drawable_hdpi_splash_image, mobile_android_app_src_main_res_drawable_mdpi_splash_image, mobile_android_app_src_main_res_drawable_xhdpi_splash_image, mobile_android_app_src_main_res_drawable_xxhdpi_splash_image, mobile_android_app_src_main_res_drawable_xxxhdpi_splash_image [INFERRED 0.95]
- **Splash screen dark variants (night-hdpi, night-mdpi, night-xhdpi, night-xxhdpi, night-xxxhdpi)** — mobile_android_app_src_main_res_drawable_night_hdpi_splash_image, mobile_android_app_src_main_res_drawable_night_mdpi_splash_image, mobile_android_app_src_main_res_drawable_night_xhdpi_splash_image, mobile_android_app_src_main_res_drawable_night_xxhdpi_splash_image, mobile_android_app_src_main_res_drawable_night_xxxhdpi_splash_image [INFERRED 0.95]
- **Android launcher icon density variants** — mobile_android_app_src_main_res_mipmap_mdpi_ic_launcher_image, mobile_android_app_src_main_res_mipmap_xhdpi_ic_launcher_image, mobile_android_app_src_main_res_mipmap_xxhdpi_ic_launcher_image, mobile_android_app_src_main_res_mipmap_xxxhdpi_ic_launcher_image [INFERRED 0.95]
- **iOS app icon size variants** — mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_1024x1024_1x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_2x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_3x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_1x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_2x_image, mobile_ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_3x_image [INFERRED 0.95]
- **iOS launch image resolution variants** — mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimage_image, mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimage_2x_image, mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimage_3x_image, mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimagedark_image, mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimagedark_2x_image, mobile_ios_runner_assets_xcassets_launchimage_imageset_launchimagedark_3x_image [INFERRED 0.95]

## Communities (215 total, 70 thin omitted)

### Community 0 - "FR Docs & Rulebook"
Cohesion: 0.05
Nodes (85): DEC-010: Portal staff sign-in (username/password), Cheat sheet (rulebook R1–R8), Definition of Done (R6), ID conventions (R7): FR/BUG/ADR/CR/DEC, Capybara Lifecycle: init→project→plan→dev→review→deploy, POST /auth/portal/login (staff sign-in, DEC-010), M3 Build Spec: Google Sign-In, BRIEF-DONATION-001: What to expect when you donate (+77 more)

### Community 1 - "Donor Profile API"
Cohesion: 0.06
Nodes (25): Transactional, DonorController, GetMapping, RequestMapping, RestController, DonorProfile, Entity, Table (+17 more)

### Community 2 - "Auth Controller Endpoints"
Cohesion: 0.06
Nodes (31): AuthController, HttpServletRequest, PostMapping, RequestMapping, ResponseEntity, RestController, ChangePasswordRequest, FcmTokenRequest (+23 more)

### Community 3 - "API Errors & DTOs"
Cohesion: 0.08
Nodes (19): Any, ApiException, ApplicationEventPublisher, Service, MatchService, Entity, Table, RequestMatch (+11 more)

### Community 4 - "Drift Generated Schema"
Cohesion: 0.03
Nodes (60): ColumnFilters, ColumnOrderings, DateTime?, GeneratedColumn, GeneratedDatabase, int get, _openConnection, PendingSync (+52 more)

### Community 5 - "Flutter Widget Tests"
Cohesion: 0.08
Nodes (51): Card, main, _wrap, main, _match, _request, _settle, _wrap (+43 more)

### Community 6 - "Mobile Error & Result Types"
Cohesion: 0.06
Nodes (40): auth_session_json.dart, blood_request.dart, blood_request_draft.dart, ../../../core/error/dio_failure_mapper.dart, ../../../core/error/failure.dart, ../../../core/error/result.dart, dart:convert, ../data/match_sync_dao.dart (+32 more)

### Community 7 - "Portal Bootstrap & Demo Decisions"
Cohesion: 0.05
Nodes (53): Portal bootstrap config: PORTAL_ADMIN_PASSWORD / PORTAL_STAFF_PASSWORD, no default, V13__staff_password_login.sql — seeds admin portal login, V19__unseed_portal_passwords.sql — replaces committed digests with random BCrypt hashes, DEC-012: local-machine demo before Play Store, docker-compose.lan.yml — LAN publish overlay for physical devices, Decisions Register (docs/decisions.md), DEC-002: FCM request-alert push moves to M4; token registration moves to M3, DEC-003: Metrics event capture per-milestone requirement (later withdrawn by DEC-004) (+45 more)

### Community 8 - "Eligibility Calculator"
Cohesion: 0.08
Nodes (21): EligibilityResponse, EligibilityCalculator, Candidate, DonorCandidateRepository, Query, Candidate, Service, Transactional (+13 more)

### Community 9 - "Blood Request Entity"
Cohesion: 0.10
Nodes (11): BloodRequest, Entity, Table, Created, BloodRequest, BeforeEach, MatchService, BeforeEach (+3 more)

### Community 10 - "API Contract Change Requests"
Cohesion: 0.05
Nodes (48): CR-MAPI-003: request contact + district shared shape, CR-MAPI-004: PUT /donors/me gains updateCoordinates, Idempotency-Key for POST /matches/{id}/respond, Three response rules (no lat/lng, rounded distanceKm, contact after acceptance), POST /auth/google, DonorProfileWrite schema, GET/PUT /donors/me, POST /matches/{id}/respond (+40 more)

### Community 11 - "Admin Staff Service"
Cohesion: 0.14
Nodes (4): AssignStaffRoleRequest, CreateStaffAccountRequest, AdminServiceTest, Test

### Community 12 - "Auth Service Tests"
Cohesion: 0.13
Nodes (3): Transactional, AuthServiceTest, Test

### Community 13 - "Board & Donation Services"
Cohesion: 0.11
Nodes (21): DistrictRepository, DonationRepository, DonationService, Service, DonorProfileRepository, HospitalRepository, HospitalService, Service (+13 more)

### Community 14 - "Riverpod Providers Core"
Cohesion: 0.05
Nodes (44): @Deprecated, AsyncValue, AutoDisposeFutureProvider, AutoDisposeFutureProviderElement, AutoDisposeFutureProviderRef, class, ../data/dio_request_repository.dart, Family (+36 more)

### Community 15 - "Auth Security Reviews"
Cohesion: 0.06
Nodes (45): AuthServiceTest, DonorServiceTest, FirebaseGoogleTokenVerifier, SignInRateLimiter (Bucket4j), Foundation Spec: Docker Compose (local dev), TC-AUTH-001: Google Sign-In cannot be bypassed or escalated, FR-AUTH-003 Google Sign-In, ASVS Controls Mapped to 8 FRs (+37 more)

### Community 16 - "Dio Failure Mapping"
Cohesion: 0.10
Nodes (36): dart:typed_data, DioException, HttpClientAdapter, ConflictFailure, Failure, ForbiddenFailure, NetworkFailure, NotFoundFailure (+28 more)

### Community 17 - "Mobile Auth Repositories"
Cohesion: 0.06
Nodes (38): DioAuthRepository, DioTelegramAuthRepository, FirebaseFacebookCredentials, AuthRepository, FacebookCredentials, GoogleCredentials, TelegramAuthRepository, _FakeAuthRepository (+30 more)

### Community 18 - "Riverpod Repo Wiring"
Cohesion: 0.06
Nodes (41): @Riverpod, authRepositoryProvider, ../../../core/database/database_providers.dart, ../data/dio_match_repository.dart, ../data/offline_first_match_repository.dart, dioRequestRepositoryProvider, facebookCredentialsProvider, googleCredentialsProvider (+33 more)

### Community 19 - "Portal Staff Actions"
Cohesion: 0.10
Nodes (28): actionErrorFlag(), assignStaffRoleAction(), createStaffAccountAction(), demoteStaffAction(), revokeStaffAction(), Copy, CreateAccountForm(), SearchableOption (+20 more)

### Community 20 - "Mobile Auth Service"
Cohesion: 0.06
Nodes (38): auth_service.dart, ../../../core/config/env.dart, ../../../core/network/auth_token_gateway.dart, ../data/dio_auth_repository.dart, ../data/dio_telegram_auth_repository.dart, ../data/firebase_facebook_credentials.dart, ../data/firebase_google_credentials.dart, ../data/secure_session_store.dart (+30 more)

### Community 21 - "Donation Repository Queries"
Cohesion: 0.18
Nodes (7): ConfirmDonationRequest, Transactional, BloodRequest, District, DonorProfile, Test, PortalServiceTest

### Community 22 - "Prototypes & Data Tables"
Cohesion: 0.09
Nodes (40): PortalController (backend), V1__init.sql migration, AUTH-portal-signin (dropped flow), blood_compatibility table, blood_requests table, donations table, DonorProfileScreen, donor_profiles table (+32 more)

### Community 23 - "Mobile DB & Location"
Cohesion: 0.06
Nodes (32): app_database.dart, appDatabaseProvider, authTokenGatewayProvider, device_location_service.dart, location_service.dart, appDatabase, DeviceLocationService, locationServiceProvider (+24 more)

### Community 24 - "District & Public Donor"
Cohesion: 0.12
Nodes (14): District, Entity, Table, DistrictName, Service, HospitalResponse, Transactional, AcceptedDonorResponse (+6 more)

### Community 25 - "Match Controller"
Cohesion: 0.09
Nodes (18): MatchResponse, RespondResponse, GetMapping, PostMapping, RequestMapping, RestController, MatchController, BloodRequestDetailResponse (+10 more)

### Community 26 - "Donation History UI"
Cohesion: 0.08
Nodes (30): ../application/donation_providers.dart, ../../../core/widgets/retryable_failure.dart, ../domain/blood_type.dart, ../../donor/application/donor_providers.dart, ../../donor/domain/donor_profile.dart, ../../donor/presentation/donor_setup_screen.dart, ../../donor/presentation/eligibility_card.dart, ../../match/application/match_providers.dart (+22 more)

### Community 27 - "Admin Controller"
Cohesion: 0.11
Nodes (16): AdminController, GetMapping, PostMapping, RequestMapping, ResponseEntity, ResponseStatus, RestController, AdminService (+8 more)

### Community 28 - "Defense Deck v2 Builder"
Cohesion: 0.26
Nodes (32): blank(), bullets(), footer(), heading(), main(), notes(), parse_milestones(), Max 6 items, max 12 words each — detail belongs in the speaker notes.… (+24 more)

### Community 29 - "Portal Landing & Sign-In"
Cohesion: 0.09
Nodes (24): HomePage(), signInAction(), SignInError, SignInPage(), ADR-0002, Copy, SignInForm(), ADR-0007 (+16 more)

### Community 30 - "Backend Config & CI"
Cohesion: 0.08
Nodes (32): backend/pom.xml — java.version must match CI, application.yml — main Spring Boot config, application-local.yml — Swagger UI enabled for local profile, Matching config: max-notified=25, radius-km=10, Telegram auth config block — inert until three env vars set (FR-AUTH-004), application-test.yml — test-only config values, Gap 4: Firebase project does not exist yet, Four gaps blocking M3 sign-off (+24 more)

### Community 31 - "Mobile Assets & Config"
Cohesion: 0.07
Nodes (32): SchemaIntegrationTest / Testcontainers Silent-Skip Trap, Flutter Analyzer Config, Launcher Artwork README, BrandBadge Icon Source (Icons.bloodtype gradient), Inter Font OFL License, Kantumruy Pro Font OFL License, Bundled Fonts README, Rationale: Bundle Fonts for Offline-First + CI Golden-Test Determinism (+24 more)

### Community 32 - "Donor Setup UI"
Cohesion: 0.10
Nodes (21): ../application/donor_providers.dart, ../application/donor_setup_controller.dart, blood_type_grid.dart, ../../../core/location/location_providers.dart, ../../../core/widgets/searchable_picker.dart, district_dropdown.dart, ../domain/eligibility.dart, donor_setup_screen.dart (+13 more)

### Community 33 - "Scope Cut & Risks"
Cohesion: 0.11
Nodes (30): /fr-security-check command, docs/po/features/ — FR documents, M4 Overloaded Risk, Scope Cut Risk Effects (DEC-004), docs/scope.md — 19 FRs requested, 8 built, 8 deferred, DEC-004 Scope Cut Decision, FR-DONATION-001 Donation History, FR-DONOR-001 Donor Profile (+22 more)

### Community 34 - "Portal Confirm Donation"
Cohesion: 0.11
Nodes (22): confirmDonationAction(), ConfirmDonationForm(), Copy, Copy, donorKey(), DonorViewModel, progressStyle(), RequestList() (+14 more)

### Community 35 - "UI Screenshots & Goldens"
Cohesion: 0.11
Nodes (29): Blood Type Badge, Request Board (Open Requests List), Board Public (English), Board Public (Khmer), Landing Page (Khmer), Eligibility Status Card, Mobile Donor Home (Khmer), Mobile Onboarding Intro (Khmer) (+21 more)

### Community 36 - "PRD & Architecture ADRs"
Cohesion: 0.10
Nodes (29): PRD FR-01: Authentication (Google Sign-In), PRD FR-02: Donor Registration & Profile, docs/risks.md — project risk register, FR-MATCH-001 Matching, Microservices Split Raised and Rejected, ADR 0001: Stack & Architecture, ADR 0002 — Auth via Google Sign-In, not phone OTP, FCM Push In-App as Unverified-Phone Mitigation (+21 more)

### Community 37 - "App Icon Family"
Cohesion: 0.07
Nodes (29): LifeLink app icon, Android launcher icon (mdpi), Android launcher icon (xhdpi), Android launcher icon (xxhdpi), Android launcher icon (xxxhdpi), LifeLink app icon, Round app icon, Play Store icon (512x512) (+21 more)

### Community 38 - "Capybara Brief & Setup"
Cohesion: 0.08
Nodes (27): Feature Areas (brief, R7): AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL, LifeLink KH Project Brief, Sensitivity Declaration (R5): auth, PII, secrets, integrations, JWT config block: secret + one-hour lifetime, Capybara Setup — LifeLink KH, Acting User Roles (R2) — Nem Sothea solo driver, Feature Areas (R7): AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL GLOBAL SECURITY MOBILE, Security Triggers In Scope (R5) (+19 more)

### Community 39 - "Hospital Entity"
Cohesion: 0.10
Nodes (7): Hospital, Entity, Table, HospitalServiceTest, District, Hospital, Test

### Community 40 - "Project Plan & Milestones"
Cohesion: 0.12
Nodes (27): CLAUDE.md — LifeLink KH Project Plan, LifeLink Architecture: Spring Boot API + PostgreSQL behind Flutter and Next.js, M1 — ERD, wireframes, API spec (W3-4), M2 — Spring Boot/Flutter/Next.js init, docker-compose up (W5-6), M3 — Google Sign-In + donor register + FCM token registration (W7-9), M4 — Request create, ABO/Rh + distance matching, eligibility, request-alert push, accept/decline (W10-12), M5 — Donation history, eligibility status, hospital web page (W13), M6 — GPS, i18n, Android build, iOS build, bug fix (W14) (+19 more)

### Community 41 - "TS Config"
Cohesion: 0.07
Nodes (26): compilerOptions, allowJs, esModuleInterop, incremental, isolatedModules, jsx, lib, module (+18 more)

### Community 42 - "Mobile Service Tests"
Cohesion: 0.10
Nodes (22): main, main, main, main, main, OutlinedButton, package:flutter_test/flutter_test.dart, package:lifelink_kh/src/app.dart (+14 more)

### Community 43 - "Match Respond Flow"
Cohesion: 0.27
Nodes (5): RespondRequest, Transactional, ApplicationEventPublisher, Test, MatchServiceTest

### Community 44 - "Schema Integration Tests"
Cohesion: 0.14
Nodes (7): ActiveProfiles, JdbcTemplate, PostgreSQLContainer, SpringBootTest, Test, Testcontainers, SchemaIntegrationTest

### Community 45 - "Mobile Donor Service"
Cohesion: 0.10
Nodes (23): ../data/dio_donor_repository.dart, ../domain/district.dart, ../domain/donor_profile.dart, ../domain/donor_profile_draft.dart, ../domain/donor_repository.dart, donor_service.dart, donorRepositoryProvider, FutureProviderRef (+15 more)

### Community 46 - "Defense Deck v1 Builder"
Cohesion: 0.33
Nodes (25): blank(), bullets(), footer(), heading(), main(), notes(), parse_milestones(), Max 6 items, max 12 words each — detail belongs in the speaker notes.… (+17 more)

### Community 47 - "Request Form Screens"
Cohesion: 0.10
Nodes (22): ../application/request_form_controller.dart, ../../auth/presentation/sign_in_screen.dart, ConsumerState, ConsumerStatefulWidget, ../core/settings/onboarding_controller.dart, ../../donation/presentation/donation_history_screen.dart, ../../donor/presentation/blood_type_grid.dart, home_tab.dart (+14 more)

### Community 48 - "Backend Auth Service"
Cohesion: 0.14
Nodes (17): ApplicationArguments, ApplicationRunner, AuthService, Logger, PasswordEncoder, Service, GoogleTokenVerifier, VerifiedIdentity (+9 more)

### Community 49 - "Global Exception Handler"
Cohesion: 0.19
Nodes (10): Detail, ErrorResponse, GlobalExceptionHandler, ResponseEntity, GlobalExceptionHandlerTest, Test, DataIntegrityViolationException, ExceptionHandler (+2 more)

### Community 50 - "Telegram Auth Challenge"
Cohesion: 0.11
Nodes (4): Entity, PrePersist, Table, TelegramAuthChallenge

### Community 51 - "Locale Store"
Cohesion: 0.09
Nodes (20): dart:io, dart:ui, locale_store.dart, InMemoryLocaleStore, LocaleStore, PreferencesLocaleStore, AppTheme, testExecutable (+12 more)

### Community 53 - "Push Registration"
Cohesion: 0.09
Nodes (17): ../../auth/application/auth_providers.dart, ../../auth/domain/auth_session.dart, dart:async, ../domain/push_arrival.dart, ../domain/push_token_source.dart, PushRegistrationService, pushSessionSync, firebasePushArrivals (+9 more)

### Community 54 - "District Controller"
Cohesion: 0.15
Nodes (11): DistrictController, GetMapping, RequestMapping, RestController, DistrictService, Service, Transactional, DistrictResponse (+3 more)

### Community 55 - "App Router & Theme"
Cohesion: 0.09
Nodes (21): core/theme/app_theme.dart, ../features/auth/application/auth_providers.dart, ../features/auth/presentation/sign_in_screen.dart, ../features/donation/presentation/donation_guide_screen.dart, ../features/donation/presentation/donation_history_screen.dart, ../features/donor/presentation/donor_profile_screen.dart, ../features/donor/presentation/donor_setup_screen.dart, ../features/home/presentation/home_screen.dart (+13 more)

### Community 56 - "Request Flow Integration Test"
Cohesion: 0.19
Nodes (13): AutoConfigureMockMvc, ActiveProfiles, BeforeEach, JdbcTemplate, MockMvc, ObjectMapper, PostgreSQLContainer, SpringBootTest (+5 more)

### Community 57 - "Firebase Token Verifier"
Cohesion: 0.16
Nodes (11): FirebaseGoogleTokenVerifier, Component, Logger, Override, FirebaseConfig, Component, Logger, FirebaseGoogleTokenVerifierTest (+3 more)

### Community 58 - "Public Board Service"
Cohesion: 0.19
Nodes (11): BoardService, Service, Transactional, PublicDonorResponse, PublicRequestResponse, BoardControllerTest, ActiveProfiles, Import (+3 more)

### Community 59 - "QA Bugs & Build Traps"
Cohesion: 0.11
Nodes (22): backend/pom.xml, docker-compose.yml, frontend/Dockerfile, OfflineFirstMatchRepository, SchemaIntegrationTest, sqlite3_flutter_libs dependency, V3__seed_districts.sql, V7__seed_hospitals.sql (+14 more)

### Community 60 - "Health Check Mobile"
Cohesion: 0.10
Nodes (18): ../../../core/network/api_client.dart, ../data/dio_health_repository.dart, ../domain/health_repository.dart, ../domain/health_status.dart, health_service.dart, healthRepositoryProvider, healthServiceProvider, healthStatusProvider (+10 more)

### Community 61 - "FCM Token Providers"
Cohesion: 0.10
Nodes (20): ../data/dio_fcm_token_repository.dart, ../data/firebase_push_token_source.dart, fcmTokenRepositoryProvider, pushRegistrationServiceProvider, fcmTokenRepository, pushArrivals, pushRegistrationService, pushTokenSource (+12 more)

### Community 62 - "Donation Entity"
Cohesion: 0.14
Nodes (4): Donation, Entity, PrePersist, Table

### Community 63 - "Donation Controller"
Cohesion: 0.18
Nodes (11): DonationController, GetMapping, RequestMapping, RestController, DonationResponse, DonationControllerTest, ActiveProfiles, Import (+3 more)

### Community 64 - "Donation History Tests"
Cohesion: 0.12
Nodes (17): _donation, _FakeDonationRepository, main, _MutableDonationRepository, _wrap, _FakeDonationRepository, main, _FakeDonationRepository (+9 more)

### Community 65 - "Dead Token Cleanup"
Cohesion: 0.16
Nodes (8): DeadTokenCleaner, Component, Logger, Transactional, Query, PushRecipientRepository, FirebaseMessagingException, Modifying

### Community 66 - "Portal Password Bootstrap"
Cohesion: 0.28
Nodes (6): BeforeEach, PasswordEncoder, Test, PortalPasswordBootstrapTest, ILoggingEvent, ListAppender

### Community 67 - "Portal Change Password"
Cohesion: 0.15
Nodes (13): changePasswordAction(), ChangePasswordResult, ChangePasswordForm(), Copy, signOutAction(), ADR-0007, SignOutButton(), apiPost() (+5 more)

### Community 68 - "App Entry & Onboarding Store"
Cohesion: 0.11
Nodes (17): main, InMemoryOnboardingStore, OnboardingStore, PreferencesOnboardingStore, onboarding_store.dart, package:firebase_core/firebase_core.dart, package:shared_preferences/shared_preferences.dart, src/app.dart (+9 more)

### Community 69 - "Telegram Auth Service"
Cohesion: 0.16
Nodes (8): TelegramAuthChallengeRepository, Logger, Service, Transactional, TelegramAuthService, TelegramBotClient, BeforeEach, SecureRandom

### Community 70 - "iOS Runner"
Cohesion: 0.12
Nodes (13): Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate, SceneDelegate (+5 more)

### Community 71 - "LifeLink App Shell"
Cohesion: 0.12
Nodes (18): ChangeNotifier, ConsumerWidget, ../../../core/settings/locale_controller.dart, ../../donation/presentation/donation_guide_screen.dart, ../../donor/presentation/donor_profile_screen.dart, LifeLinkApp, DonationHistoryScreen, DistrictDropdown (+10 more)

### Community 72 - "Portal Requests Page"
Cohesion: 0.22
Nodes (14): PortalPage(), sortByUrgency(), URGENCY_RANK, ChangePasswordPage(), ADR-0002, AdminPage(), listFulfilledRequests(), listOpenRequests() (+6 more)

### Community 73 - "User Account Model"
Cohesion: 0.18
Nodes (5): AuthenticatedUser, AuthResponse, Entity, Table, User

### Community 74 - "JWT Service"
Cohesion: 0.25
Nodes (6): Service, JwtService, Test, JwtServiceTest, Claims, SecretKey

### Community 75 - "Acceptance Notifier"
Cohesion: 0.21
Nodes (6): DonorAccepted, AcceptanceNotifier, Component, Logger, RequesterRecipient, TransactionalEventListener

### Community 76 - "Mobile Request Domain"
Cohesion: 0.14
Nodes (13): ../domain/blood_request.dart, ../domain/blood_request_draft.dart, ../domain/hospital.dart, ../domain/request_repository.dart, ../domain/requester_contact.dart, ../../donor/domain/blood_type.dart, RequestService, BloodRequest (+5 more)

### Community 77 - "Telegram DTOs"
Cohesion: 0.20
Nodes (9): TelegramStartRequest, TelegramStartResponse, TelegramVerifyRequest, HttpServletRequest, PostMapping, RequestMapping, ResponseEntity, RestController (+1 more)

### Community 78 - "Telegram Bot Client"
Cohesion: 0.19
Nodes (8): HttpTelegramBotClient, Component, Logger, ObjectMapper, Override, Component, TelegramConfig, HttpClient

### Community 79 - "Mobile API Client"
Cohesion: 0.12
Nodes (15): apiClientProvider, auth_interceptor.dart, ../config/env.dart, _addDebugLogging, apiClient, _baseOptions, createApiClient, createSignInApiClient (+7 more)

### Community 80 - "Mobile Match Domain"
Cohesion: 0.14
Nodes (13): ../application/match_providers.dart, ../application/request_providers.dart, ../../../core/time/relative_time.dart, ../domain/request_status.dart, Match, MatchDetailScreen, _MatchDetailScreenState, RequestDetailScreen (+5 more)

### Community 81 - "Health & Swagger"
Cohesion: 0.22
Nodes (10): HealthController, GetMapping, RestController, ActiveProfiles, Import, MockMvc, Test, WebMvcTest (+2 more)

### Community 82 - "Mobile Failure Mapper"
Cohesion: 0.17
Nodes (13): failure.dart, _errorCode, failureFromDio, Failed, Result, Success, main, _match (+5 more)

### Community 83 - "Telegram Webhook Tests"
Cohesion: 0.25
Nodes (7): TelegramSession, ActiveProfiles, Import, MockMvc, Test, WebMvcTest, TelegramAuthControllerTest

### Community 84 - "Urgency & Picker"
Cohesion: 0.16
Nodes (11): ../domain/urgency.dart, _PickerSheet, _PickerSheetState, SearchablePicker, Urgency, UrgencyBadge, _UrgencyBadgeState, UrgencySelector (+3 more)

### Community 85 - "Frontend Dev Dependencies"
Cohesion: 0.13
Nodes (15): eslint, devDependencies, eslint, prettier, tailwindcss, @tailwindcss/postcss, @types/react, typescript (+7 more)

### Community 86 - "Portal Layout & i18n"
Cohesion: 0.21
Nodes (8): inter, kantumruyPro, metadata, LOCALE_LABEL, { Link, usePathname, useRouter }, Locale, routing, config

### Community 87 - "Onboarding Controller"
Cohesion: 0.16
Nodes (13): _, onboardingControllerProvider, OnboardingController, onboardingStore, telegramVerifyControllerProvider, TelegramVerifyController, donorSetupProvider, DonorSetup (+5 more)

### Community 88 - "Sign-In Screen"
Cohesion: 0.18
Nodes (12): ../application/auth_providers.dart, auth_failure_message.dart, ../../../core/widgets/brand_badge.dart, ../domain/telegram_start_session.dart, _PendingProvider, SignInScreen, _SignInScreenState, _CodeEntry (+4 more)

### Community 89 - "Security Config"
Cohesion: 0.26
Nodes (9): Bean, Configuration, ObjectMapper, PasswordEncoder, SecurityConfig, CorsConfigurationSource, EnableWebSecurity, HttpSecurity (+1 more)

### Community 90 - "Request Alert Notifier"
Cohesion: 0.24
Nodes (5): PushRecipient, Component, Logger, RequestAlertNotifier, SendResponse

### Community 91 - "Mobile Session Store"
Cohesion: 0.17
Nodes (9): auth_session.dart, SecureSessionStore, AuthUser, SessionStore, _InMemorySessionStore, _GatedSessionStore, FakeSessionStore, telegram_start_session.dart (+1 more)

### Community 92 - "Mobile Donation Providers"
Cohesion: 0.18
Nodes (12): ../data/dio_donation_repository.dart, donation_service.dart, donationRepositoryProvider, myDonationsControllerProvider, donationRepository, donationService, MyDonationsController, donationRepositoryProvider (+4 more)

### Community 93 - "Frontend Package Scripts"
Cohesion: 0.17
Nodes (11): name, private, scripts, build, dev, format, format:check, lint (+3 more)

### Community 94 - "Match Sync DAO"
Cohesion: 0.18
Nodes (10): @DriftAccessor, @DriftDatabase, ../../../core/database/app_database.dart, dart:math, DatabaseAccessor, _$MatchSyncDaoMixin, AppDatabase, MatchSyncDao (+2 more)

### Community 95 - "JWT Auth Filter"
Cohesion: 0.29
Nodes (8): Component, HttpServletRequest, ObjectMapper, Override, JwtAuthFilter, FilterChain, HttpServletResponse, OncePerRequestFilter

### Community 96 - "District Controller Tests"
Cohesion: 0.35
Nodes (6): DistrictControllerTest, ActiveProfiles, Import, MockMvc, Test, WebMvcTest

### Community 97 - "Health Service Tests"
Cohesion: 0.18
Nodes (9): Exception, health_status.dart, HealthRepository, main, _StubRepository, FakeHealthRepository, package:lifelink_kh/src/features/home/application/health_service.dart, package:lifelink_kh/src/features/home/domain/health_repository.dart (+1 more)

### Community 98 - "Portal Time Helpers"
Cohesion: 0.31
Nodes (7): AutoRefresh(), RelativeTime(), isToday(), minutesOld(), relativeAge, isoMinutesAgo(), NOW

### Community 99 - "Android 12 Splash"
Cohesion: 0.18
Nodes (11): LifeLink Android 12+ splash screen, Android 12+ splash screen (hdpi), Android 12+ splash screen (mdpi), Android 12+ splash screen dark (night-hdpi), Android 12+ splash screen dark (night-mdpi), Android 12+ splash screen dark (night-xhdpi), Android 12+ splash screen dark (night-xxhdpi), Android 12+ splash screen dark (night-xxxhdpi) (+3 more)

### Community 100 - "Android Splash Screens"
Cohesion: 0.18
Nodes (11): App splash screen (hdpi), App splash screen (mdpi), App splash screen dark (night-hdpi), App splash screen dark (night-mdpi), App splash screen dark (night-xhdpi), App splash screen dark (night-xxhdpi), App splash screen dark (night-xxxhdpi), App splash screen (xhdpi) (+3 more)

### Community 101 - "Match Repositories"
Cohesion: 0.18
Nodes (11): DioMatchRepository, OfflineFirstMatchRepository, MatchRepository, _FakeMatchRepository, _FakeMatchRepository, _FakeMatchRepository, _FakeMatchRepository, _FakeMatchRepository (+3 more)

### Community 102 - "Maven Wrapper"
Cohesion: 0.33
Nodes (6): mvnw script, clean(), die(), exec_maven(), set_java_home(), verbose()

### Community 103 - "Data Model Tables"
Cohesion: 0.33
Nodes (10): blood_requests table, districts table, donations table, Rationale: donations is sole source of eligibility truth, donor_profiles table, Rationale: donor_profiles kept separate from users, hospitals table, request_matches table (+2 more)

### Community 104 - "Donor Registration Test"
Cohesion: 0.20
Nodes (9): FilledButton, _completeIdentityStep, _completeSetup, main, _pickDistrict, package:lifelink_kh/src/core/location/location_providers.dart, package:lifelink_kh/src/features/donor/application/donor_providers.dart, package:lifelink_kh/src/features/donor/presentation/donor_profile_screen.dart (+1 more)

### Community 105 - "Auditable Base Entity"
Cohesion: 0.31
Nodes (4): Auditable, PrePersist, MappedSuperclass, PreUpdate

### Community 106 - "Health Controller Tests"
Cohesion: 0.39
Nodes (6): HealthControllerTest, ActiveProfiles, Import, MockMvc, Test, WebMvcTest

### Community 107 - "Public Board Contract"
Cohesion: 0.25
Nodes (9): DEC-009: Public request board, GET /public/requests (mobile-facing public board), AcceptedDonor schema, POST /portal/requests/{id}/confirm-donation (openapi), GET /portal/requests (openapi), PortalRequest schema, GET /public/requests (portal spec), PublicDonor schema (+1 more)

### Community 108 - "dependencies"
Cohesion: 0.22
Nodes (9): dependencies, next, next-intl, react, react-dom, next, next-intl, react (+1 more)

### Community 109 - "board.ts"
Cohesion: 0.39
Nodes (5): listPublicRequests(), PublicDonor, apiGet(), ApiResult, Health

### Community 110 - "DioRequestRepository"
Cohesion: 0.22
Nodes (9): DioRequestRepository, RequestRepository, _FakeRequestRepository, _FakeRequestRepository, _FakeRequestRepository, _FakeRequestRepository, _CountingRequestRepository, _FakeRequestRepository (+1 more)

### Community 111 - "district.dart"
Cohesion: 0.25
Nodes (7): district.dart, donor_profile.dart, donor_profile_draft.dart, DioDonorRepository, DonorRepository, _FakeDonorRepository, FakeDonorRepository

### Community 112 - "HospitalController.java"
Cohesion: 0.43
Nodes (4): HospitalController, GetMapping, RequestMapping, RestController

### Community 113 - "DataClass"
Cohesion: 0.38
Nodes (7): DataClass, Insertable, UpdateCompanion, PendingSyncCompanion, PendingSyncData, RequestMatchRow, RequestMatchRowsCompanion

### Community 114 - "AuthController.java"
Cohesion: 0.29
Nodes (7): AuthController.java, AuthService.java, FirebaseConfig.java, GoogleTokenVerifier.java, JwtAuthFilter.java, JwtService.java, ADR 0007: Session lifetime and expiry

### Community 115 - "Foundation Spec: Spring Boot API + Postg"
Cohesion: 0.29
Nodes (7): Foundation Spec: Spring Boot API + PostgreSQL, Foundation Spec: Next.js Web Portal, Error-shape conflict (web contract vs ErrorResponse), next-intl (i18n library), backend compose service, postgres compose service, web compose service

### Community 116 - "iOS launch image"
Cohesion: 0.29
Nodes (7): iOS launch image, iOS launch image @2x, iOS launch image @3x, iOS launch image @1x, iOS launch image dark @2x, iOS launch image dark @3x, iOS launch image dark @1x

### Community 117 - "JacksonConfig.java"
Cohesion: 0.53
Nodes (4): JacksonConfig, Bean, Configuration, Jackson2ObjectMapperBuilderCustomizer

### Community 118 - "OpenApiConfig.java"
Cohesion: 0.53
Nodes (4): Bean, Configuration, OpenApiConfig, OpenAPI

### Community 119 - "TimeConfig.java"
Cohesion: 0.53
Nodes (4): Bean, Configuration, TimeConfig, EnableScheduling

### Community 120 - "TelegramUpdate.java"
Cohesion: 0.73
Nodes (5): Chat, From, Message, TelegramUpdate, JsonIgnoreProperties

### Community 121 - "blood_type.dart"
Cohesion: 0.33
Nodes (4): blood_type.dart, eligibility.dart, DonorProfile, DonorProfileDraft

### Community 122 - ".prettierrc.json"
Cohesion: 0.33
Nodes (5): printWidth, semi, singleQuote, tabWidth, trailingComma

### Community 123 - "LifeLink app icon background"
Cohesion: 0.33
Nodes (6): LifeLink app icon background, App icon background (hdpi), App icon background (mdpi), App icon background (xhdpi), App icon background (xxhdpi), App icon background (xxxhdpi)

### Community 124 - "LifeLink app icon foreground (blood drop"
Cohesion: 0.33
Nodes (6): LifeLink app icon foreground (blood drop + cross), App icon foreground (hdpi), App icon foreground (mdpi), App icon foreground (xhdpi), App icon foreground (xxhdpi), App icon foreground (xxxhdpi)

### Community 125 - "BUG-BUILD-003: Testcontainers skipped sc"
Cohesion: 0.40
Nodes (5): BUG-BUILD-003: Testcontainers skipped schema tests, fixed with docker.api.version property, BUG-INFRA-001: host PostgreSQL owns port 5432, compose moved to 5433, BUG-WEB-002: Next standalone bound to container ID, fixed with ENV HOSTNAME=0.0.0.0, disabledWithoutDocker=true still turns a stopped daemon into a green build, M2 sign-off state (2026-08-17)

### Community 126 - "CR-MAPI-001: districtName carries both l"
Cohesion: 0.40
Nodes (5): CR-MAPI-001: districtName carries both labels, CR-MAPI-002: GET /districts endpoint, DistrictName schema {km,en}, GET /districts, GET /portal/requests

### Community 127 - "match_detail_screen.dart (PENDING badge)"
Cohesion: 0.40
Nodes (5): match_detail_screen.dart (PENDING badge), match_sync_dao.dart, match_sync_service.dart (SyncService, S2 exception), offline_first_match_repository.dart, offline_first_match_test.dart (12 tests)

### Community 128 - "CR-SEC Change Request Template"
Cohesion: 0.50
Nodes (5): CR-SEC Change Request Template, CR-SEC Registry (any → Security, next: 001), Security Overlay Scope (held by Tech Lead), SEC-REVIEW Template (verdict: pass | fail | pass-with-conditions), Threat Model Template (STRIDE, assets, trust boundaries, residual risk)

### Community 129 - "eslint.config.mjs"
Cohesion: 0.40
Nodes (4): compat, __dirname, eslintConfig, __filename

### Community 130 - "Launcher background"
Cohesion: 0.40
Nodes (5): Launcher background, Launcher background dark (night), Launcher background dark (night-v21), Launcher background (v21), LifeLink launcher background

### Community 131 - "Week 1 Slides: Setup & Flutter Project A"
Cohesion: 0.40
Nodes (5): Week 1 Slides: Setup & Flutter Project Anatomy, Rule #1: Feature-First Folder Structure, Week 2 Slides: go_router & Material 3 Theming, go_router Declarative Routing, Material 3 ColorScheme.fromSeed Theming

### Community 132 - "b64()"
Cohesion: 0.70
Nodes (4): b64(), main(), read_secret(), seeded_user_id()

### Community 133 - "auth_token_gateway.dart"
Cohesion: 0.50
Nodes (3): auth_token_gateway.dart, Interceptor, AuthInterceptor

### Community 135 - "POST /auth/telegram/start"
Cohesion: 0.50
Nodes (4): POST /auth/telegram/start, POST /auth/telegram/verify, POST /auth/telegram/webhook, TM-AUTH-002: Telegram auth threat model

### Community 136 - "GET/POST /admin/staff"
Cohesion: 0.50
Nodes (4): GET/POST /admin/staff, POST /admin/staff/{id}/demote, POST /admin/staff/{id}/revoke, GET /admin/users

### Community 139 - "Bug Report Template"
Cohesion: 0.67
Nodes (3): Bug Report Template, BUG-<AREA>-<###> Defect ID Convention, QA Role Scope

### Community 145 - "iOS launch background"
Cohesion: 0.67
Nodes (3): iOS launch background, iOS launch background light, iOS launch background dark

## Ambiguous Edges - Review These
- `docs/po/presentations/run-of-show.md` → `FR-PORTAL-003: Admin-Managed Staff Accounts`  [AMBIGUOUS]
  docs/po/presentations/run-of-show.md · relation: conceptually_related_to
- `SEC-REVIEW-001 Verdict: Pass-With-Conditions` → `SEC-REVIEW-002 Telegram Sign-In`  [AMBIGUOUS]
  docs/security/reviews/SEC-REVIEW-001-google-sign-in.md · relation: references
- `Landing Page (Khmer)` → `Mobile Onboarding Intro (Khmer)`  [AMBIGUOUS]
  docs/assets/screens/landing-km.png · relation: semantically_similar_to

## Knowledge Gaps
- **608 isolated node(s):** `kh.lifelink:lifelink-api`, `singleQuote`, `tabWidth`, `printWidth`, `semi` (+603 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **70 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `docs/po/presentations/run-of-show.md` and `FR-PORTAL-003: Admin-Managed Staff Accounts`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `SEC-REVIEW-001 Verdict: Pass-With-Conditions` and `SEC-REVIEW-002 Telegram Sign-In`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Landing Page (Khmer)` and `Mobile Onboarding Intro (Khmer)`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **Why does `Locale` connect `Portal Layout & i18n` to `App Router & Theme`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Why does `User` connect `User Account Model` to `Dead Token Cleanup`, `Portal Password Bootstrap`, `API Errors & DTOs`, `Telegram Auth Service`, `Auditable Base Entity`, `Admin Staff Service`, `Auth Service Tests`, `Board & Donation Services`, `Backend Auth Service`, `Telegram Challenge Repo`, `Donation Repository Queries`, `Admin Controller`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `UserRepository` connect `Backend Auth Service` to `Portal Password Bootstrap`, `API Errors & DTOs`, `Telegram Auth Service`, `User Account Model`, `Admin Staff Service`, `Auth Service Tests`, `Board & Donation Services`, `Telegram Challenge Repo`, `Donation Repository Queries`, `Admin Controller`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `User` (e.g. with `.verify()` and `.verify_ignores_the_challenge_role_for_a_returning_chat_id()`) actually correct?**
  _`User` has 2 INFERRED edges - model-reasoned connections that need verification._