# Product Requirements Document (PRD)

## Project: LifeLink KH (ជីវិត) — Blood Donor Matching App

| Field | Detail |
|---|---|
| Version | 1.0 |
| Date | 2026-07-24 |
| Author | Team LifeLink KH (Track B) |
| Status | Draft |

---

## 1. Project Overview

### Purpose
LifeLink KH connects patients and families who urgently need blood with nearby eligible
voluntary donors. A Flutter mobile app serves donors and requesters; a Next.js web portal
serves hospitals and administrators. Both run on one Spring Boot + PostgreSQL backend.

### Problem Statement
Cambodia faces chronic blood shortages. Hospitals and the National Blood Transfusion
Center currently find emergency donors through ad-hoc Facebook posts — slow, unreliable,
and impossible to target by blood type or location. When a patient needs blood fast,
there is no systematic way to alert matching donors nearby. Lives are lost to delay.

### Target Users
- **Donor** — a voluntary blood donor (mobile app).
- **Requester** — a patient or family member seeking blood (mobile app).
- **Hospital Staff** — verifies requests and confirms donations (web portal).
- **Administrator** — manages users, hospitals, and moderation (web portal).

### Success Metrics
- **≥ 200** registered donors in Phnom Penh within the first month of pilot.
- **≥ 70%** of urgent requests receive at least one donor acceptance within 60 minutes.
- **Median time** from request creation to first donor acceptance **< 30 minutes**.
- **≥ 50** completed, hospital-verified donations during the pilot semester.
- Push notification delivery rate **≥ 95%**.

---

## 2. Scope

### 2.1 In Scope

**Module A — Accounts & Auth**
- Phone-number registration with OTP verification.
- Donor profile: name, blood type, location, last donation date.
- Role selection (donor / requester); hospital & admin accounts provisioned by admin.

**Module B — Donor Management**
- Create/edit donor profile.
- Automatic eligibility status from the 56-day cooldown rule.
- Availability toggle (available / unavailable to be contacted).

**Module C — Urgent Requests & Matching**
- Requester creates an urgent blood request (blood type, units, hospital, urgency).
- System matches eligible, available donors by ABO/Rh compatibility and distance.
- Push notification to matching donors.
- Donor accepts / declines a request; requester and hospital see responders.

**Module D — Donation History & Reminders**
- Record of each donation (date, hospital, request link).
- 56-day cooldown tracking; push reminder when the donor becomes eligible again.

**Module E — Hospital / Admin Portal (Web)**
- Hospital: view and manage requests for their facility; confirm completed donations.
- Admin: manage users, hospitals, moderate requests, view reports/metrics.

**Cross-cutting**
- Khmer + English localization on both clients.
- Location capture (GPS on mobile; manual on web).

### 2.2 Out of Scope (deferred to future versions)
- In-app chat / messaging between donor and requester (use phone call in v1).
- Payment, rewards, or gamification.
- Integration with national health / hospital record systems.
- iOS release (Android Play Store only for the course requirement).
- Blood inventory / stock management for hospitals.
- Automated identity/medical verification of donors (manual by hospital in v1).

---

## 3. User Roles & Personas

### Donor
- **Description:** A healthy volunteer willing to give blood, using the mobile app.
- **Goals:** Register, be notified only for relevant nearby requests, track own donations, know when eligible again.
- **Permissions:** Manage own profile; view/accept/decline requests matched to them; view own history. Cannot see other donors' data or create requests for others.

### Requester
- **Description:** A patient or family member needing blood, using the mobile app.
- **Goals:** Post an urgent need quickly and see who is coming to help.
- **Permissions:** Create/cancel own requests; view responders to own requests. Cannot browse the donor directory.

### Hospital Staff
- **Description:** Staff at a partner hospital, using the web portal.
- **Goals:** Track incoming requests tied to their hospital; confirm when a donation actually happened.
- **Permissions:** View/manage requests for their own hospital; confirm donations; view responders. Cannot manage users or other hospitals.

### Administrator
- **Description:** LifeLink KH operator, using the web portal.
- **Goals:** Keep the platform healthy, onboard hospitals, moderate abuse, report impact.
- **Permissions:** Full access — manage users, hospitals, requests, and view all metrics.

---

## 4. Functional Requirements

### FR-01: Phone Authentication (OTP)

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Donor, Requester, Hospital Staff, Admin |
| Description | Register and sign in with a phone number verified by a one-time password. |

**User Stories:**
- As a donor, I want to sign up with my phone number, so that I don't need to remember a password.
- As a user, I want to verify via OTP, so that my account is tied to a real phone.

**Acceptance Criteria:**
- [ ] User enters a Cambodian phone number and receives an OTP.
- [ ] Correct OTP within the validity window creates/authenticates the account.
- [ ] Wrong or expired OTP is rejected with a clear message.
- [ ] A session token is issued on success and used for subsequent API calls.

### FR-02: Donor Registration & Profile

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Donor |
| Description | Create and edit a donor profile with blood type, location, and last donation date. |

**User Stories:**
- As a donor, I want to enter my blood type and location, so that I only get relevant requests.
- As a donor, I want to set an availability toggle, so that I'm not contacted when I can't donate.

**Acceptance Criteria:**
- [ ] Required fields: name, blood type (A/B/AB/O × +/−), location (GPS or district), phone.
- [ ] Optional: last donation date.
- [ ] Availability toggle defaults to available.
- [ ] Profile is editable at any time.

### FR-03: Eligibility Check (56-day cooldown)

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Donor (system-computed) |
| Description | System computes whether a donor is currently eligible based on last donation date. |

**User Stories:**
- As a donor, I want the app to know when I'm eligible, so that I don't get requests I can't answer.

**Acceptance Criteria:**
- [ ] Eligible when no last donation date, or last donation ≥ 56 days ago.
- [ ] Ineligible donors are excluded from matching.
- [ ] Donor sees own eligibility status and the date they become eligible again.

### FR-04: Create Urgent Request

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Requester, Hospital Staff |
| Description | Create an urgent blood request specifying blood type, units, hospital, and urgency. |

**User Stories:**
- As a requester, I want to post an urgent need in under a minute, so that help arrives fast.

**Acceptance Criteria:**
- [ ] Required: patient blood type, units needed, hospital/location, urgency level.
- [ ] On creation, matching + notification runs automatically.
- [ ] Requester can cancel or mark the request fulfilled.
- [ ] Request has a status: open / fulfilled / cancelled / expired.

### FR-05: Donor Matching (blood type + distance)

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | System |
| Description | Find eligible, available donors compatible with the request, ranked by distance. |

**User Stories:**
- As a requester, I want the right donors alerted, so that compatible help is found quickly.

**Acceptance Criteria:**
- [ ] Matching honors ABO/Rh compatibility (see Glossary), not just exact type.
- [ ] Only eligible + available donors are matched.
- [ ] Donors ranked by distance to the request location.
- [ ] Configurable radius (default 10 km) and max notified count.

### FR-06: Push Notifications

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Donor |
| Description | Deliver time-critical alerts to matched donors' phones via FCM. |

**User Stories:**
- As a donor, I want an instant alert for a nearby matching request, so that I can act immediately.

**Acceptance Criteria:**
- [ ] Matched donors receive a push within seconds of request creation.
- [ ] Tapping the notification opens the request detail in the app.
- [ ] Reminder notifications sent when a donor becomes eligible again.

### FR-07: Respond to Request (Accept / Decline)

| Field | Detail |
|---|---|
| Priority | Must Have |
| User Role | Donor |
| Description | Donor accepts or declines a matched request; requester/hospital see responders. |

**User Stories:**
- As a donor, I want to accept a request, so that the family knows I'm coming.
- As a requester, I want to see who accepted, so that I know help is on the way.

**Acceptance Criteria:**
- [ ] Donor can accept or decline from the request detail.
- [ ] Accepting reveals the hospital/contact info to the donor.
- [ ] Requester and hospital see the list of accepting donors with contact.

### FR-08: Donation History

| Field | Detail |
|---|---|
| Priority | Should Have |
| User Role | Donor, Hospital Staff |
| Description | Track each completed donation, linked to a request and hospital. |

**User Stories:**
- As a donor, I want to see my donation history, so that I feel my impact.

**Acceptance Criteria:**
- [ ] A donation record stores date, hospital, and (optionally) linked request.
- [ ] Completing a donation updates the donor's last donation date (drives FR-03).
- [ ] Hospital staff can confirm a donation happened.

### FR-09: Eligibility Reminder

| Field | Detail |
|---|---|
| Priority | Should Have |
| User Role | Donor |
| Description | Notify a donor when the 56-day cooldown ends and they can donate again. |

**User Stories:**
- As a donor, I want a reminder when I'm eligible again, so that I return to donate.

**Acceptance Criteria:**
- [ ] Push sent on the day eligibility is regained.
- [ ] Donor's status flips to eligible automatically.

### FR-10: Hospital Request Management (Web)

| Field | Detail |
|---|---|
| Priority | Should Have |
| User Role | Hospital Staff |
| Description | Web portal to view/manage requests for the hospital and confirm donations. |

**User Stories:**
- As hospital staff, I want to see all requests for my hospital, so that I can coordinate donors.

**Acceptance Criteria:**
- [ ] Staff sees only their hospital's requests.
- [ ] Staff can view responders and confirm completed donations.

### FR-11: Admin Dashboard (Web)

| Field | Detail |
|---|---|
| Priority | Should Have |
| User Role | Admin |
| Description | Manage users, hospitals, and view platform metrics. |

**User Stories:**
- As an admin, I want to onboard hospitals and see metrics, so that I can run the platform.

**Acceptance Criteria:**
- [ ] Admin can create/disable hospital and staff accounts.
- [ ] Admin can view the success metrics from Section 1.
- [ ] Admin can moderate (remove) abusive requests or users.

### FR-12: Localization (Khmer / English)

| Field | Detail |
|---|---|
| Priority | Should Have |
| User Role | All |
| Description | Full Khmer and English UI on both clients, switchable at runtime. |

**User Stories:**
- As a Khmer user, I want the app in Khmer, so that I understand it fully.

**Acceptance Criteria:**
- [ ] All user-facing strings available in Khmer and English.
- [ ] Language switch persists across sessions.

---

## 5. Non-Functional Requirements

| Area | Definition |
|---|---|
| **Performance** | Request-to-first-notification < 10 s; API p95 < 500 ms; supports 1,000 registered donors, 100 concurrent users in pilot. |
| **Security** | OTP auth, JWT session tokens, HTTPS/TLS everywhere, role-based access control. Donor contact details revealed only after accepting a request. |
| **Scalability** | Design for 10,000 donors and multiple provinces without schema change. |
| **Availability** | 99% uptime target during pilot; nightly PostgreSQL backups. |
| **Compatibility** | Mobile: Android 8.0+ (Play Store). Web: latest Chrome, Firefox, Edge, Safari. |
| **Localization** | Khmer (default) + English; local Cambodia time; 24-hour clock. |

---

## 6. Data Requirements

### Key Entities
- **User** — identity, phone, role, language, FCM token.
- **DonorProfile** — blood type, location (lat/lng + district), last donation date, availability.
- **Hospital** — name, location, contact.
- **BloodRequest** — patient blood type, units, hospital, urgency, status, created-by.
- **RequestMatch** — links a request to a notified donor + response (accepted/declined).
- **Donation** — donor, hospital, date, linked request.

### Relationships
- User (1) ─ (0..1) DonorProfile.
- Hospital (1) ─ (0..*) BloodRequest.
- BloodRequest (1) ─ (0..*) RequestMatch ─ (1) DonorProfile.
- DonorProfile (1) ─ (0..*) Donation.

### Data Retention
- Requests retained 2 years for impact reporting, then anonymized.
- Donation history retained for the donor's account lifetime.
- Users may request account + personal data deletion.

### Sensitive Data
- Phone numbers and precise location are sensitive — encrypted in transit, access-controlled.
- Donor contact exposed to a requester only upon the donor accepting a request.
- Blood type is health data — treat as confidential.

---

## 7. User Flows

#### Flow: Donor Onboarding
1. User opens app, enters phone number.
2. System sends OTP; user enters it.
3. System verifies, creates account.
4. User picks role "Donor", enters blood type + location + last donation date.
5. User sees own eligibility status and dashboard.

#### Flow: Urgent Request (core)
1. Requester taps "Request Blood", enters blood type, units, hospital, urgency.
2. System matches eligible/available compatible donors within radius.
3. System sends push to matched donors.
4. Donor taps notification, views request, taps Accept.
5. Requester sees the accepting donor and contact; they coordinate by phone.
6. Hospital confirms the donation; donor's last-donation date updates.

#### Flow: Eligibility Reminder
1. 56 days pass since a donor's last donation.
2. System flips donor to eligible and sends a reminder push.
3. Donor is again included in future matching.

#### Flow: Error / Edge Cases
- **No matching donors:** requester is told none found now; system widens radius or retries; hospital notified.
- **OTP fails/expires:** clear error, allow resend after a short cooldown.
- **Donor accepts but can't come:** donor can withdraw acceptance; requester notified.
- **Duplicate request:** system warns if an identical open request exists.

---

## 8. Assumptions & Dependencies

### Assumptions
- Donors have Android smartphones with data/Wi-Fi and can receive push.
- Users have Cambodian phone numbers that can receive SMS OTP.
- Hospitals will designate staff to use the web portal.
- The 56-day interval is the eligibility rule used for whole-blood donation.

### Dependencies
- Firebase Cloud Messaging (push) and an SMS/OTP provider.
- Google Maps / geocoding for distance and district lookup.
- Google Play Console for Play Store internal-testing release.

### Risks
- **Low donor density early** → mitigate with campus/NGO onboarding drives.
- **SMS OTP cost/deliverability** → mitigate by evaluating providers early; fallback to Firebase phone auth.
- **False/abusive requests** → mitigate with admin moderation and hospital confirmation.
- **Privacy concern over location** → mitigate by exposing contact only after acceptance and storing minimal data.

---

## 9. Glossary

| Term | Definition |
|---|---|
| **ABO/Rh** | Blood group system (A, B, AB, O) with Rhesus factor (+/−). |
| **Compatibility** | A recipient of type X can receive from specific donor types (e.g., O− is universal donor; AB+ universal recipient). Matching uses this, not exact-type only. |
| **Eligibility** | Whether a donor may donate now; here, ≥ 56 days since last donation. |
| **Cooldown** | The 56-day rest period after donating whole blood. |
| **OTP** | One-Time Password sent to a phone for verification. |
| **FCM** | Firebase Cloud Messaging — push notification service. |
| **Match** | A donor selected by the system as compatible + eligible + nearby for a request. |
| **Requester** | Person creating a blood request (patient/family). |
| **Internal testing** | A Google Play release track for a limited tester group (the course M7 target). |
