# Prototypes

Wireframes and clickable mock-ups. The middle step of the PO flow — where a brief becomes
something a teammate can look at and disagree with, before anyone writes code.

## What a prototype is for

To settle **screen-level questions** that a written brief cannot: how many steps a flow takes,
what a donor sees on the notification tap, whether a Khmer label fits the button.

A prototype is throwaway. It is not a design system, not production assets, and never
imported by `mobile/` or `frontend/` code.

## Where a prototype sits in the PO flow

Per `../CLAUDE.md`:

```
brief (../briefs/)  →  prototype (here)  →  finalize FR (Scope + acceptance criteria)
```

The prototype exists to make the FR's **acceptance criteria** writable. Once the FR is
finalized, the prototype is frozen — later UI changes go through the FR or a `CR-PO`
change request, not by silently editing a wireframe.

## Two clients, two prototype sets

| Client | Prototype for | Consumed by |
|---|---|---|
| **Flutter mobile** | Donor + Requester screens | Mobile role (`docs/mobile/`) |
| **Next.js web portal** | Hospital Staff + Admin screens | Fullstack role (`docs/fullstack/`) |

Keep them in separate subfolders — `mobile/` and `web/` — because the same feature looks
different on each and reviewers only care about one.

## Naming

`<client>/<AREA>-<slug>/` — one folder per flow, holding its screens in order.

```
prototypes/
  mobile/
    AUTH-otp-signin/
      01-phone-entry.png
      02-otp-entry.png
      README.md          ← what question this prototype answers
    REQUEST-create-urgent/
  web/
    PORTAL-hospital-requests/
```

Areas match R7 (`docs/cheat-sheet.md`):
`AUTH DONOR REQUEST MATCH DONATION NOTIFY PORTAL GLOBAL SECURITY MOBILE`

Each flow folder gets a short `README.md` stating the question it answers and the answer
it produced. A wireframe with no written conclusion teaches nobody.

## Formats

- **Wireframes** — PNG/SVG export, plus the source (Figma link in the flow `README.md`).
- **Clickable mock-ups** — link only. Do not commit a mock-up tool's build output.
- **Text wireframes** — plain Markdown ASCII layout is fine and preferred for a single screen.
  Cheapest to review in a diff.

Commit exports, not editable binaries, when the source lives in a hosted tool.

## Rules

- PO writes here. Nobody else. (Write-scope rule, `../CLAUDE.md`.)
- Every screen with user-facing text needs **both Khmer and English** shown or noted —
  Khmer is the default language (`../prd.md` section 5) and it is longer than English.
  A layout that only fits English is a layout that fails.
- A prototype never invents data the API doesn't have. Cross-check against
  `docs/fullstack/api-contract/` before drawing a field.
- Frozen prototypes stay in the repo. They are the record of why a screen looks like it does.

## Related

- [`roadmap.md`](roadmap.md) — which flows get prototyped in which milestone.
- [`../briefs/`](../briefs/) — the step before this.
- [`../features/index.md`](../features/index.md) — the step after; FRs cite prototypes via `brief_ref:`.
- [`../prd.md`](../prd.md) section 7 — the four user flows to prototype first.
