---
id: 0004-abo-rh-compatibility-lookup-table
title: ABO/Rh compatibility lives in a database lookup table
status: accepted
date: 2026-08-07
deciders: Tech Lead
---

## Context

FR-MATCH-001 ranks donors who are compatible, eligible and nearby. Compatibility is not
equality — a patient needing A+ can receive from A+, A−, O+ and O−. Matching on exact blood type
would shrink the candidate pool roughly fourfold, which matters most in the pilot, when donor density
is lowest (the top risk in the PRD).

The 27 valid (recipient, donor) pairs can live in application code or in the database.

## Decision

A seeded lookup table, `blood_compatibility (recipient_type, donor_type)`, primary key on both
columns, populated in `V1__init.sql` with all 27 rows.

The matching query then joins it, so compatibility, eligibility and distance stay a single SQL
statement:

```sql
SELECT dp.* FROM donor_profiles dp
JOIN blood_compatibility bc ON bc.donor_type = dp.blood_type
WHERE bc.recipient_type = :patientBloodType
  AND dp.is_available
  AND (dp.last_donation_date IS NULL OR dp.last_donation_date <= CURRENT_DATE - INTERVAL '56 days')
-- distance ordering added once ADR 0003 settles location storage
```

The 27 rows, for the migration:

| Recipient | Compatible donors |
|---|---|
| O− | O− |
| O+ | O−, O+ |
| A− | O−, A− |
| A+ | O−, O+, A−, A+ |
| B− | O−, B− |
| B+ | O−, O+, B−, B+ |
| AB− | O−, A−, B−, AB− |
| AB+ | all eight |

Rule the table encodes: a donor must carry no ABO antigen the recipient lacks, and an Rh− recipient
must never receive Rh+ blood. Rh+ recipients may receive either.

## Consequences

Matching stays one query with no round trip to filter candidates in Java, and it stays correct as the
donor pool grows — the database can index and plan it.

The table is also **testable data rather than a branch**. QA can assert all 27 rows exist and that no
28th does, which is a far stronger check than reading a nested conditional. Getting this wrong is a
patient-safety error, not a bug: giving A+ blood to an O− recipient causes a haemolytic reaction. That
is the whole reason it goes somewhere reviewable.

Costs, accepted: the rule is medical fact and cannot change, so keeping it in a table buys no genuine
runtime flexibility — the argument is reviewability, not configurability. It also means a `JOIN` on
every match and one more table to seed, and the seed data must be verified against a clinical source
during review, not against this ADR.

Whole blood only. Plasma compatibility is the inverse of red-cell compatibility and platelets differ
again; the app does not model them, and this table must not be reused if it ever does.

## Alternatives considered

- **Hard-coded map in the matching service** — rejected. Compatibility becomes invisible to QA and to
  the database planner, and candidate filtering moves into application memory.
- **Derive from antigen flags** (`has_a`, `has_b`, `rh_pos` columns) — rejected. Elegant, and the
  predicate is genuinely short, but it puts a clinical rule inside a boolean expression that a
  reviewer has to simulate mentally. The explicit table is auditable by inspection.
