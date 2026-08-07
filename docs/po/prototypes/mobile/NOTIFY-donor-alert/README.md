# NOTIFY-donor-alert (mobile)

**Milestone:** M1 wireframe · freeze before M4 build
**FR:** [`FR-NOTIFY-001-request-push-alert`](../../../features/FR-NOTIFY-001-request-push-alert.md),
[`FR-REQUEST-002-respond-accept-decline`](../../../features/FR-REQUEST-002-respond-accept-decline.md)

## Questions this settles

1. What does a donor see **before** accepting?
2. What does accepting reveal?
3. How do donor and requester actually coordinate, now that phone numbers are unverified?

## Answers

1. Blood type, hospital, urgency, rounded distance, units. **Not** the patient's name and not the
   requester's contact — a donor decides on the medical and logistical facts, and nothing else is
   theirs to see yet.
2. **Mutual reveal, one direction at a time.** On accept, the requester's contact becomes visible to
   this donor, and this donor becomes visible to the requester. Before accept, neither.
3. **In-app, through the request thread.** This is the mitigation the auth change created a debt for
   (ADR 0002) — phone numbers are unverified, so the app cannot promise a call connects. Contact
   details are shown as a convenience; the push channel is the guarantee.

> Khmer strings are a first pass — native check needed before M4.

## Screen 1 — Push notification (lock screen)

```
┌─────────────────────────────────┐
│  ជីវិត LifeLink KH        ឥឡូវនេះ   │
│  ─────────────────────────────  │
│  🩸 ត្រូវការឈាម A+ នៅជិតអ្នក         │
│     A+ blood needed near you    │
│                                 │
│  មន្ទីរពេទ្យកាល់ម៉ែត្រ · ~២.៥ គ.ម     │
│  Calmette Hospital · ~2.5 km    │
└─────────────────────────────────┘
```

Four facts and no more: type, "near you", hospital, distance. Enough to decide whether to open it,
not enough to leak anything if the phone is on a table.

**No patient name, ever** — not here, not in the app. `blood_requests` has no name column
(`data-model.md`), so it cannot appear by accident.

Distance is `~2.5 km`, rounded to 0.5 km per ADR 0003. The tilde is not cosmetic; it tells the donor
this is approximate and stops "it said 2.5 km but it was 4".

## Screen 2 — Request detail (after tap, before deciding)

```
┌─────────────────────────────────┐
│  ←                              │
│  ┌───────────────────────────┐  │
│  │  បន្ទាន់ / URGENT           │  │  ← amber; red if CRITICAL
│  └───────────────────────────┘  │
│                                 │
│           A+                    │
│      ត្រូវការ ១ ឯកតា               │
│      1 unit needed              │
│                                 │
│  ────────────────────────────   │
│  មន្ទីរពេទ្យ / Hospital          │
│  មន្ទីរពេទ្យកាល់ម៉ែត្រ              │
│  Calmette Hospital              │
│  ស្ទឹងមានជ័យ · ~២.៥ គ.ម            │
│  Stung Meanchey · ~2.5 km       │
│                                 │
│  ស្នើសុំនៅ / Requested            │
│  ១៤ នាទីមុន / 14 minutes ago     │
│  ────────────────────────────   │
│                                 │
│  ក្រុមឈាមរបស់អ្នក O− អាចផ្តល់បាន      │
│  Your O− blood is compatible    │
│                                 │
│  ┌──────────┐ ┌──────────────┐  │
│  │ បដិសេធ    │ │  យល់ព្រម      │  │
│  │ Decline  │ │  Accept      │  │  ← green, wider
│  └──────────┘ └──────────────┘  │
└─────────────────────────────────┘
```

"Your O− blood is compatible" is worth the line. A donor who knows they are O− and sees an A+ request
will otherwise assume the app made a mistake and decline.

"14 minutes ago" carries the urgency that a status badge cannot. A 4-hour-old open request tells a
donor something real.

**Decline is a real button, not a dismiss.** A declined donor is recorded
(`request_matches.response = 'DECLINED'`) so they are not re-alerted for the same request, and so the
requester's count means something.

## Screen 3 — After accepting

```
┌─────────────────────────────────┐
│              ✓                  │
│  អរគុណ។ អ្នកបានយល់ព្រម              │
│  Thank you — you accepted       │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ទៅមន្ទីរពេទ្យកាល់ម៉ែត្រ       │  │
│  │  Go to Calmette Hospital  │  │
│  │  ~២.៥ គ.ម / ~2.5 km        │  │
│  └───────────────────────────┘  │
│                                 │
│  ────────────────────────────   │
│  ទាក់ទងគ្រួសារ / Contact family  │
│                                 │
│   Sophea  ·  012 345 678        │
│   ┌─────────────────────────┐   │
│   │  📞  ទូរស័ព្ទ / Call     │   │
│   └─────────────────────────┘   │
│                                 │
│  ⓘ លេខនេះមិនបានផ្ទៀងផ្ទាត់          │
│    This number is not           │
│    verified. If it does not     │
│    connect, message here        │
│   ┌─────────────────────────┐   │
│   │  💬  សារក្នុងកម្មវិធី      │   │
│   │      Message in app     │   │
│   └─────────────────────────┘   │
│  ────────────────────────────   │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ខ្ញុំមិនអាចទៅបានទេ           │  │
│  │  I can no longer go       │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

This screen is where ADR 0002's carried debt gets paid. Three things make it honest:

1. The phone number is shown **and labelled unverified**. Hiding the caveat would be worse than
   hiding the number.
2. **In-app messaging is the fallback and is always present**, not a link surfaced after failure. It
   is the channel the app can actually guarantee, because it rides the same FCM token that delivered
   the alert.
3. **"I can no longer go"** is here even though `FR-REQUEST-004` (withdraw) is deferred (DEC-004). In
   this build the button opens the message thread rather than changing state — a donor who cannot
   come must be able to say so, and silence is the worst outcome for the family.

> **Blocks M4:** in-app messaging is not an FR. It appears in `prd.md` §7 as "they coordinate by
> phone" only. Either a minimal message thread is added to the M4 build, or this screen degrades to
> phone-only and the unverified-number risk in `docs/risks.md` stays live with no mitigation. Tech
> Lead call — the risk register currently claims FCM coordination as the mitigation, so choosing
> phone-only means correcting that entry too.

## Cross-check against the API

`patient_blood_type`, `units_needed`, `urgency`, `status`, `created_at` from `blood_requests`;
`hospitals.name` + district; distance computed server-side and returned rounded (ADR 0003);
`request_matches.response` / `responded_at` for accept and decline.

Requester contact comes from `users.phone` and is returned **only** when this donor's
`request_matches.response = 'ACCEPTED'` — the I1 mitigation in
[`TM-AUTH-001`](../../../../security/threat-models/TM-AUTH-001-google-sign-in.md), verified by
`TC-AUTH-001` case 12.

No latitude or longitude appears on any screen in this flow.

## What is deliberately absent

- A map. `geolocator` reads coordinates; distance is a number (DEC-004).
- Patient name, age, condition. Never collected.
- Other donors' identities. A donor sees their own decision, not a leaderboard.
