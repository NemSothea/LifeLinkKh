# Demo script — explaining LifeLink KH to someone seeing it for the first time

**Owner:** PO. **Not a course deliverable** — M8 (`CLAUDE.md` §4, `DEC-008`) is ungraded. This is
the *narration* for a demo; the *commands* to actually stand the app up live in
[`../demo-runbook.md`](../demo-runbook.md). Usually the same person holds both, switching hats
between running the stack and talking through it.

Read this once before a defense, then talk from memory — a script read verbatim sounds like a
script. The point is to know the shape of the story well enough to tell it naturally, and to have
the right sentence ready for the moments people always ask about.

Read [section 8](#8-the-day-before) first if the demo is soon — two of the items there take
longer than an evening.

---

## 1. The hook (30 seconds, before touching a device)

Say this, don't paraphrase it into something longer:

> "Right now, when a hospital in Phnom Penh needs blood urgently, staff post it to Facebook and
> wait. That's not a joke — it's the actual current process. It doesn't target by blood type,
> doesn't know who's nearby, and doesn't reach anyone who isn't already scrolling at that exact
> moment. LifeLink KH replaces that with something that pushes an alert straight to the phone of
> every eligible, nearby donor the second a request is created."

That one paragraph is the entire pitch. Everything after this is proving it.

## 2. Who's in the room (name the cast before the click-through starts)

Three roles, two apps:

- **Donor** and **Requester** — same mobile app, same sign-in, different tab set after. A donor
  whose relative needs blood is the app's own expected requester, so nothing forces a person to
  pick one identity forever.
- **Admin** — the web portal, one account (`soborey`). Never self-signed-up. v1 has no
  hospital-staff accounts (`DEC-014`): the admin confirms donations for every hospital. If asked
  "how do hospitals get accounts," say that is a deliberate v2 decision — don't volunteer it
  unprompted, it's a side quest.

Two devices (or two emulators) side by side is the whole demo. One phone plays donor, one plays
requester, the laptop's browser plays the portal.

Both clients open in Khmer and both can switch to English in-app — the portal from the top-right
switcher, the phone from the **Me** tab, one item above sign-out. Say it only if someone in the
room cannot read Khmer, then switch the phone and keep going; a demo where half the audience is
decoding glyphs is not a demo.

## 3. The walkthrough — narrate each step as you (or your partner) click it

Match this to `../demo-runbook.md` §4's golden path. The commands are there; here's what to *say*
at each one.

**Step 0 — the app introduces itself (fresh install only).**
> "Before anything asks for an account, three slides say what the app does — one donation reaching
> up to three patients, alerts sent only to compatible donors nearby, and the app counting the
> cooldown for you. Skippable, and never shown again after the first launch."

Ten seconds, then move on. It matters because the version before it opened straight onto a Google
Sign-In button — asking a stranger for their identity before telling them why. If the demo device
has already run the app, this screen will not appear: either say so or reinstall before the room
fills up.

**Step 1 — donor registers.**
> "This is Account A. Google Sign-In, no password, no OTP to wait for — one tap and they're
> signed in. They pick blood type and district. Notice there's no phone number field —
> earlier drafts had one, we cut it deliberately: without a verified phone, collecting a number
> nobody can trust the app to call is worse than not collecting it. Coordination happens through
> the app's own push notifications instead."

Use the pinned values, do not improvise them: **O−**, **Doun Penh**, last-donation date left
blank. `../demo-runbook.md` §4 has the table and the reason for each one — every field on this
screen is a filter that can quietly remove this donor from the match you are about to demo.

If asked why district and not exact GPS coordinates: *"Exact coordinates would publish someone's
home address next to their blood type. District-level distance is accurate enough for triage, not
precise enough to find a specific house."* (`ADR 0003`, don't cite the number out loud, just the
reasoning.)

**Step 2 — requester creates an urgent request.**
> "Account B — different person, same app, same sign-in. They pick blood type, urgency, hospital,
> units needed. Pinned: **Calmette**, patient type **AB+**, **CRITICAL**. One screen, not a wizard — someone doing this is frightened, not calm, so the form
> defaults to something valid even if they touch nothing."

**Step 3 — the match happens, the push fires.** (Only on the real Firebase project. On the local
emulator stack no push is delivered — the request simply appears in Account A's list; say "on a
live deployment this is a notification" and move on, `../demo-runbook.md` §0.)
> "Watch Account A's phone now — no manual refresh, no polling. A cloud function just matched
> compatible blood type plus eligible plus nearby, and Firebase pushed it straight to the device.
> This is the moment the Facebook-post version of this process can't do: instant, targeted, not
> dependent on who happens to be scrolling."

**Step 4 — donor accepts, and the push goes the other way.**
> "One tap. Now watch Account B — the family's phone. 'A donor accepted your request.' Push runs
> in both directions: the donor was told someone needs blood, the family is told someone answered.
> Notice what the family does *not* see — the donor's name. They see that one donor is coming; the
> portal sees who, because the portal is where the donation is confirmed."

Added 2026-09-25 (`FR-NOTIFY-003`). Account B must be on a device that receives FCM — a phone or
an Android emulator. On the iOS Simulator this beat silently does nothing.

**Step 4b — the same need, seen from outside.**
> "Look at the bottom of this donor's home screen — every open request nearby, not only the ones
> matched to them. A donor who wasn't alerted can still choose to help, and the same board is a
> public web page: no app, no account, just a link you can send to someone."

This is worth the extra thirty seconds. Matched alerts are empty most days by design — a donor is
only matched when someone nearby needs their type — and a demo that lands on an empty inbox looks
like a broken product instead of a calm one.

**Step 5 — switch to the browser, the admin confirms the donation.**
> "This is the portal — the one piece of this product that isn't a phone screen, because a desk
> isn't reaching for a phone mid-shift. The admin signs in with a username and password; nobody
> self-registers here. They see the accepted donor, and once the donation actually happens, they
> click confirm. That single click is what starts the donor's 56-day
> cooldown — the system doesn't trust a self-report, it trusts a confirmation."

Sign in as `soborey`. If asked why hospitals don't confirm their own donations: v1 is deliberately
admin-only (`DEC-014`) — one account to secure during a pilot, hospital staff roles are a v2 call.

**Step 6 — back on the donor's phone, show the history.**
> "Donation history updates, eligibility flips to a countdown. That's the loop closing — register,
> request, match, push, accept, confirm, history. Every one of those six words is a real screen you
> just watched."

## 4. If someone asks "why a phone app and not just a website"

> "Two words: push and GPS. A website can't put an alert on someone's lock screen the second a
> request is created — that's the entire point of speed here. And it can't read a phone's live
> location without being installed. A blood emergency is measured in minutes; a browser tab
> somebody isn't looking at loses those minutes."

## 5. If someone asks about something that isn't built

Don't improvise a reason. Say: *"That's a deliberate cut, not an oversight — point me to
`docs/scope.md` and I'll show you exactly why."* Then actually open it. The specific ones people
ask about most:

- **"What if nobody accepts?"** → deferred (`FR-MATCH-002`). Today the requester just sees nobody
  found yet. A real retry-with-wider-radius system is future work.
- **"Can a donor delete their account?"** → not built (`FR-SECURITY-001`), and say the honest
  reason out loud: it's a privacy obligation, deferred only because every account in this pilot is
  a team-created test account, and it comes back into scope before any real donor's data is in
  this database.
- **"Anyone can see that donor's name and blood type?"** → yes, and it was decided that way
  (`DEC-009`), not missed. A request has to be shareable with someone who has not installed
  anything, or the link is useless in the exact emergency it exists for. Every donor row today is
  a team-created test account, and `docs/scope.md` carries the consent step as a debt with the
  same deadline as account deletion — before real donor data exists in this database. Do not
  defend it as harmless; say it is a trade with a written expiry.
- **"Is there a map?"** → no, on purpose. `geolocator` reads coordinates; there's no
  `google_maps_flutter` widget. Rendering an interactive map was roughly a week of work for a
  requirement ("GPS") that a coordinate read already satisfies.

## 6. If someone asks "do you have any numbers?"

Run them, do not quote them from memory:

```bash
cd firebase && npm run metrics                            # the emulator
cd firebase && npm run metrics -- --project lifelinkkh    # the real project
```

All five PRD targets, computed off Firestore in front of the room. The sentence that has to
go with it:

> "The query is real. The pilot data is not — every row in here is an account this team made.
> So read these as the measurement working, not as a result."

Quote the denominator, never the percentage alone: the output prints one beside every figure
because "67% accepted within the hour" over three requests is not a finding. And metric 5 is
Firebase *accepting* the send, not a phone displaying it — say send-success, not delivery. Being
precise costs a sentence; being caught overstating costs the room.

## 7. Closing line

> "Everything you just watched maps onto one of eight features we chose to build completely,
> out of nineteen we could have built halfway. That trade is documented, not accidental —
> `docs/scope.md` is the paper trail if anyone wants to check."

## 8. The day before

The demo runs from **one local machine** ([DEC-012](../decisions.md)): either the Firebase
emulators on the laptop, or the real Firebase project with the laptop running the portal — see
`../demo-runbook.md` §0 for which. The phones are plugged into that laptop or, on the real
project, untethered on **your own phone's hotspot**, never the room's Wi-Fi. No store install, no
tunnel. Google Sign-In needs the internet either way, so sign both phones in before the room
fills. Everything that can fail is on a device or a network you control.

Eight things, in the order they bite:

1. **Decide: emulator or real project.** Only the real project delivers pushes. If the alert
   arriving on a phone is the moment you want the room to see, the Functions must be deployed to
   `lifelinkkh` (Blaze plan) days ahead, not the morning of.
2. **Record the fallback.** A screen recording of the golden path, narrated or silent. No network,
   no HDMI for a phone, a borrowed laptop — any of those ends a live demo, and a recording turns
   that from a failure into a shrug. Make it after any golden-path change, not the morning of.
3. **Rehearse from cold.** Emulators stopped, both device emulators closed. Run
   `../demo-runbook.md` sections 1, 3 and 4 start to finish and time it. Over six minutes means
   cutting a step, not talking faster. A rehearsal that reaches step 6 puts that donor into a
   56-day cooldown; re-seed afterwards or the next run matches nobody.
4. **Check the admin can sign in.** The portal has one account, `soborey`, created by
   `npm run seed:admin` with the password in `PORTAL_ADMIN_PASSWORD` (`../demo-runbook.md` §9). On
   the emulator it is forgotten every time the emulators stop, so re-seed it after every start. If
   you are projecting, use a password you are willing to have watched being typed, and rotate it
   afterwards.
5. **Two devices and a browser, laid out before you speak.** One donor, one requester, portal on
   the laptop. Decide which screen is projected when — switching devices mid-sentence is where
   demos lose the room.
6. **Check push actually fires on these two devices** (real project). FCM registration is
   per-install; a reinstalled device has a different token. One token is stored per account, so
   the device that last opened the app gets the push — **open the app on each demo device last**.
7. **Fresh install on the donor device** if you want Step 0 to appear at all.
8. **Check the match before Account B posts** — `../demo-runbook.md` §4 "Prove the match": the
   donor's profile compatible, available and out of cooldown, and a non-null FCM token. A request
   that matches nobody is silent, not an error — nothing on screen explains it, because
   `FR-MATCH-002` is deferred. The two that bite in rehearsal: one account playing both roles (a
   donor never matches their own request), and a donation already confirmed for that donor, which
   starts the 56-day cooldown.

---

## Related

- [`../demo-runbook.md`](../demo-runbook.md) — the commands: the emulator stack or the real
  project, the admin account, seeding demo data, and section 8's per-surface test pass
- [`../scope.md`](../scope.md) — the eight built FRs, the eight deferred, and why
- [`presentations/run-of-show.md`](presentations/run-of-show.md) — the clock: 30 minutes of
  slides with the 5-minute demo inside them, and what to cut if the slot is tighter
- [`prd.md`](prd.md) — the full product spec, for anything this script's narration compresses away
- [`../../firebase/scripts/metrics.mjs`](../../firebase/scripts/metrics.mjs) — the five PRD success
  metrics, computed off Firestore in one run (`npm run metrics`)
