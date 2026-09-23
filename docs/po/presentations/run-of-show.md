# Run of show — 30 minutes of slides, 5 minutes of demo

For `LifeLinkKH-v2.pptx` (15 slides). The demo sits **inside** the talk, not after it: the room
should see the product working before it hears how the work was managed.

Total 35:00 with the demo, against a 15-slide deck. If the slot is 30 minutes **including** the
demo, take the cut line at the bottom — do not talk faster.

## The clock

| Time | Slide | Minutes | What it has to land |
|---|---|---|---|
| 0:00 | 1 · Title | 0:30 | Say the problem, not the product. Do not read the team list |
| 0:30 | 2 · The Problem | 2:00 | Facebook post and hope. Reach without targeting is not reach |
| 2:30 | 3 · Target Users | 1:30 | Donor is the target user; everything else serves that person |
| 4:00 | 4 · Three Core Features | 2:30 | Say "one, two, three" out loud — the assignment asks for three |
| 6:30 | 5 · Why Mobile | 2:00 | Push and GPS. A website cannot reach a lock screen |
| 8:30 | 6 · Architecture | 3:00 | Two clients, one API. The longest slide, and it earns it |
| 11:30 | 7 · How We Manage Scope | 2:30 | Eight built completely, eight deferred on purpose, written down |
| 14:00 | 8–9 · Screenshots | 1:30 | 45 seconds each. Real build, real device — say that once |
| 15:30 | 10 · Live Walkthrough | 0:30 | One sentence, then switch devices |
| **16:00** | **— LIVE DEMO —** | **5:00** | See the cut below. Rehearse this to 4:30, not 5:00 |
| 21:00 | 11 · Milestones | 2:00 | M1–M6 done, M7 sequenced after the demo (DEC-012) |
| 23:00 | 12 · Where We Are Today | 2:30 | 196 backend tests, 189 mobile, verified live not just green |
| 25:30 | 13 · Success Metrics | 2:00 | Targets, not results. Offer to run `metrics.sql` live |
| 27:30 | 14 · Risks | 2:30 | Say the two security items before anyone asks |
| 30:00 | 15 · Team + Open Question | 1:30 | Ask the question, then stop talking |
| 31:30 | — | 3:30 | Questions, and slack for the demo running long |

## The 5-minute demo

Five minutes does not fit the six-step golden path. **Pre-stage the donor**: registered, signed
in, notification permission granted, sitting on the Home tab before the room walks in. Registration
is slides 8–9's job — the screenshots already show the intro and the profile, which is why they
come immediately before the demo.

| Time | Step | Said while doing it |
|---|---|---|
| 0:00 | Requester posts the request | "Different person, same app. Blood type, urgency, hospital. One screen, because someone doing this is frightened, not calm" |
| 0:45 | **The push lands on the donor's phone** | Stop talking. Let the room watch the lock screen. This is the entire pitch |
| 1:15 | Donor opens it, accepts | "One tap. The requester and the hospital both see this donor is coming" |
| 2:00 | Portal, signed in as `calmette` | "The hospital desk, in a browser. They see the accepted donor" |
| 3:00 | Confirm donation | "That click starts the 56-day cooldown. The system doesn't trust a self-report, it trusts the hospital" |
| 3:45 | Back to the phone — history | "History updates, eligibility flips to a countdown. That's the loop closing" |
| 4:30 | Buffer | Where a slow emulator or a re-tap goes |

Narration for each beat is `../demo-script.md` §3. The pre-flight, the pinned values and the five
ways this goes silent are `../../demo-runbook.md` §3 — run the pre-flight after pre-staging the
donor and before the room is in, not during.

## If the slot is 30 minutes including the demo

Cut in this order. Each line is a slide whose content survives somewhere else.

1. **Slide 3 (Target Users), −1:30.** The four roles land anyway on slide 6's two clients and in
   the demo's cast.
2. **Slide 5 (Why Mobile), −2:00.** Fold it into one sentence on slide 4: "push and GPS are why
   this is an app and not a website." Keep the full answer ready — it is the single most likely
   question, and answering it from a question is stronger than pre-empting it.
3. **Slide 13 (Metrics), −1:00 rather than cut.** Say the five targets in one breath, and offer
   to run `metrics.sql` in questions instead of walking the slide.
4. **Screenshots to 45 seconds total, −0:45.** One slide, not two, if the live demo already ran.

That is 5:15 back, which lands at 29:45 with the demo intact. **Never cut the demo to protect a
slide.** The demo is the only part of this that cannot be faked, and it is what the room remembers.
