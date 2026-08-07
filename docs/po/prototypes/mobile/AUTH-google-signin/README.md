# AUTH-google-signin (mobile)

**Milestone:** M1 wireframe · freeze before M3 build
**FR:** [`FR-AUTH-003-google-sign-in`](../../../features/FR-AUTH-003-google-sign-in.md)
**ADR:** [`0002`](../../../../tech-lead/adr/0002-auth-google-sign-in.md)

## Questions this settles

1. How many taps from cold start to a usable account?
2. What does the screen say *before* the Google account picker appears?
3. Where does role selection live — on this flow or after it?

## Answers

1. **Three taps.** Continue with Google → pick account (system sheet) → pick role. There is no
   password field, no code entry, no email confirmation.
2. It states what the app will do with the account, in one line, before any picker appears. A donor
   who taps "Continue with Google" without knowing why is a donor who uninstalls.
3. **On this flow, screen 2.** Role changes the entire home screen, so routing cannot happen without
   it. It is a two-option choice, not a settings page.

> Khmer strings below are a first pass and need a native check before M3 — mark corrections in this
> file, not in the FR.

## Screen 1 — Welcome / sign-in

```
┌─────────────────────────────────┐
│                                 │
│            ជីវិត                 │   (logo, blood-red)
│         LifeLink KH             │
│                                 │
│   ភ្ជាប់អ្នកបរិច្ចាគឈាមនៅជិតអ្នក      │
│   Connects nearby blood donors  │
│   with patients who need them   │
│                                 │
│                                 │
│  ┌───────────────────────────┐  │
│  │  G   បន្តជាមួយ Google       │  │  ← primary, full width
│  │      Continue with Google │  │
│  └───────────────────────────┘  │
│                                 │
│  យើងប្រើគណនីរបស់អ្នកដើម្បីបញ្ជាក់      │
│  អត្តសញ្ញាណតែប៉ុណ្ណោះ                │
│  We use your account to verify  │
│  who you are — nothing else     │
│                                 │
└─────────────────────────────────┘
```

No "skip" and no guest mode. Every downstream feature needs a known user
(`FR-AUTH-003` § Why), and a guest path would have to be torn out at M4.

## Screen 2 — Google account picker

System sheet. **Not ours to draw** — Firebase/Play Services renders it. Drawn here only so the tap
count is honest.

```
┌─────────────────────────────────┐
│  Choose an account              │
│  ───────────────────────────    │
│  ◉  sothea@gmail.com            │
│  ○  nem.work@gmail.com          │
│  +  Add another account         │
└─────────────────────────────────┘
```

Cancelling returns to screen 1 with no account created and no error dialog — a cancel is a choice,
not a failure (`prd.md` §7 error cases).

## Screen 3 — Role selection

```
┌─────────────────────────────────┐
│  ជំរាបសួរ Sothea                  │
│  Welcome, Sothea                │
│                                 │
│  តើអ្នកនៅទីនេះសម្រាប់អ្វី?           │
│  What are you here for?         │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ♡  ខ្ញុំចង់បរិច្ចាគឈាម        │  │
│  │     I want to donate      │  │
│  │     blood                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  !  ខ្ញុំត្រូវការឈាម            │  │
│  │     I need blood for      │  │
│  │     someone               │  │
│  └───────────────────────────┘  │
│                                 │
│  អ្នកអាចផ្លាស់ប្តូរបានពេលក្រោយ         │
│  You can change this later      │
└─────────────────────────────────┘
```

Two cards, not a dropdown — it is a fork in the road, and a dropdown hides one branch.

Wording is by intent ("I want to donate") rather than by system role name ("Donor"), because
`DONOR` / `REQUESTER` are database values, not words a panicking family reads.

**`HOSPITAL` and `ADMIN` do not appear here and must never be selectable.** Server-side allow-list
per [`TM-AUTH-001`](../../../../security/threat-models/TM-AUTH-001-google-sign-in.md) threat E1 — the
UI omitting them is not the control, the server rejecting them is.

## Cross-check against the API

Every field shown exists in the contract: `firebase_uid` (never displayed), display name from the
Google profile, `role` from screen 3. Nothing here invents data
(`../../README.md` rules).

## What this flow does NOT include

- Phone number. Collected later in `DONOR-profile-setup`, unverified (ADR 0002).
- Email display. We receive it from Google; we have no reason to show it back.
- Terms/privacy acceptance screen. Deferred with `FR-SECURITY-001` — noted so it is not mistaken
  for an oversight ([`docs/scope.md`](../../../../scope.md)).
