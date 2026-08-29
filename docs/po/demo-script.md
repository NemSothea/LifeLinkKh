# Demo script — explaining LifeLink KH to someone seeing it for the first time

**Owner:** PO. **Not a course deliverable** — M8 (`CLAUDE.md` §4, `DEC-008`) is ungraded. This is
the *narration* for a demo; the *commands* to actually stand the app up live in
[`../demo-runbook.md`](../demo-runbook.md). Usually the same person holds both, switching hats
between running the stack and talking through it.

Read this once before a defense, then talk from memory — a script read verbatim sounds like a
script. The point is to know the shape of the story well enough to tell it naturally, and to have
the right sentence ready for the moments people always ask about.

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

Four roles, two apps:

- **Donor** and **Requester** — same mobile app, same sign-in, different tab set after. A donor
  whose relative needs blood is the app's own expected requester, so nothing forces a person to
  pick one identity forever.
- **Hospital staff** and **Admin** — the web portal. Never self-signed-up; an admin grants access
  after someone has already signed in once as an ordinary user (`FR-PORTAL-003` — mention this if
  asked "how do hospitals get accounts," don't volunteer it unprompted, it's a side quest).

Two devices (or two emulators) side by side is the whole demo. One phone plays donor, one plays
requester, the laptop's browser plays the hospital portal.

## 3. The walkthrough — narrate each step as you (or your partner) click it

Match this to `../demo-runbook.md` §3's golden path. The commands are there; here's what to *say*
at each one.

**Step 1 — donor registers.**
> "This is Account A. Google Sign-In, no password, no OTP to wait for — one tap and they're
> signed in. They pick blood type and district. Notice there's no phone number field —
> earlier drafts had one, we cut it deliberately: without a verified phone, collecting a number
> nobody can trust the app to call is worse than not collecting it. Coordination happens through
> the app's own push notifications instead."

If asked why district and not exact GPS coordinates: *"Exact coordinates would publish someone's
home address next to their blood type. District-level distance is accurate enough for triage, not
precise enough to find a specific house."* (`ADR 0003`, don't cite the number out loud, just the
reasoning.)

**Step 2 — requester creates an urgent request.**
> "Account B — different person, same app, same sign-in. They pick blood type, urgency, hospital,
> units needed. One screen, not a wizard — someone doing this is frightened, not calm, so the form
> defaults to something valid even if they touch nothing."

**Step 3 — the match happens, the push fires.**
> "Watch Account A's phone now — no manual refresh, no polling. The server just matched
> compatible blood type plus eligible plus nearby, and Firebase pushed it straight to the device.
> This is the moment the Facebook-post version of this process can't do: instant, targeted, not
> dependent on who happens to be scrolling."

**Step 4 — donor accepts.**
> "One tap. The requester and the hospital can now both see this donor is coming."

**Step 5 — switch to the browser, hospital confirms the donation.**
> "This is the portal — the one piece of this product that isn't a phone screen, because a hospital
> desk isn't reaching for a phone mid-shift. They see the accepted donor, and once the donation
> actually happens, they click confirm. That single click is what starts the donor's 56-day
> cooldown — the system doesn't trust a self-report, it trusts the hospital."

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
- **"Is there a map?"** → no, on purpose. `geolocator` reads coordinates; there's no
  `google_maps_flutter` widget. Rendering an interactive map was roughly a week of work for a
  requirement ("GPS") that a coordinate read already satisfies.

## 6. Closing line

> "Everything you just watched maps onto one of eight features we chose to build completely,
> out of nineteen we could have built halfway. That trade is documented, not accidental —
> `docs/scope.md` is the paper trail if anyone wants to check."

---

## Related

- [`../demo-runbook.md`](../demo-runbook.md) — the commands: bringing the stack up, minting a
  portal token, seeding demo data
- [`../scope.md`](../scope.md) — the eight built FRs, the eight deferred, and why
- [`prd.md`](prd.md) — the full product spec, for anything this script's narration compresses away
