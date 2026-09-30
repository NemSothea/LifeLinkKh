# Community channels · បណ្តាញសហគមន៍

> Owner: PO (channels copy). Moderator: Tech Lead (Nem Sothea). Language: **Khmer first, English
> welcome**: pinned posts are in both, and anyone may write in either.
> Links stay as placeholders until the channels exist. A human creates them; nobody makes them
> from this repo.

| Channel | For | Not for | Link |
|---|---|---|---|
| **GitHub Issues** | Bugs, feature requests, translations: anything that needs tracking | Chat, emergencies, security holes | <https://github.com/NemSothea/LifeLinkKh/issues> |
| **GitHub Discussions** | Questions, ideas, proposals before a DEC, announcements | Bug reports (open an issue) | <https://github.com/NemSothea/LifeLinkKh/discussions> |
| **Telegram group** | Quick questions, news, coordinating testers and translators, Khmer-first chat | Decisions, bug tracking, personal data | `[TELEGRAM_LINK]` |
| **Facebook page** | Public news, release announcements, reaching donors and students | Support threads, technical discussion | `[FB_PAGE]` |
| **Security** | Vulnerabilities, privately | Anything public | [`SECURITY.md`](../../SECURITY.md) |

**Rule for every channel:** a bug or idea raised in chat goes to a GitHub issue. The moderator
opens it if the person can't. A decision made in chat is not a decision until it is written in an
issue, DEC or ADR ([`GOVERNANCE.md`](../../GOVERNANCE.md)).

**Never an emergency line.** LifeLink volunteers can't get blood for anyone through chat. Point
urgent requests to the app, the hospital, or the National Blood Transfusion Center.

---

## GitHub Discussions: categories

Enabled 2026-09-30. GitHub created six default categories. **Categories can't be created through
the API**, so the moderator sets them up in *Discussions → Categories (pencil icon)*:

| Category | Format | Action | Description to paste |
|---|---|---|---|
| Announcements / ដំណឹង | Announcement | rename default "Announcements" | Releases and project news. Maintainers post; everyone may comment. · ដំណឹង និងការចេញផ្សាយកំណែថ្មី។ |
| Q&A / សំណួរ-ចម្លើយ | Question/Answer | rename default "Q&A" | Ask anything about using or building LifeLink KH. · សួរអ្វីក៏បានអំពីការប្រើ ឬការអភិវឌ្ឍ។ |
| Ideas / គំនិត | Open discussion | rename default "Ideas" | Propose a feature or a change before it becomes a DEC. · ស្នើមុខងារ ឬការផ្លាស់ប្តូរ។ |
| Translation / ការបកប្រែ | Open discussion | **create new** | Khmer wording, terminology, style questions. · ពាក្យពេចន៍ និងរចនាប័ទ្មភាសាខ្មែរ។ |
| Show and tell / បង្ហាញ | Open discussion | rename default | Photos from donation drives, forks, demos. No personal data. · រូបភាព និងការបង្ហាញ (គ្មានព័ត៌មានផ្ទាល់ខ្លួន)។ |
| General | Open discussion | **delete** or keep hidden | Too vague; moves people away from the right category. |
| Polls | Poll | keep | Quick community votes. Not binding on a DEC. |

All Khmer descriptions are `[km-review]`.

---

## Telegram group: setup (human)

1. Create a **group** (not a channel) named **"LifeLink KH · ជីវិត — Community"**.
2. Settings:
   - public link `[TELEGRAM_LINK]`;
   - history visible to new members;
   - slow mode 10 s;
   - approve new members off (keep the barrier low), but turn on the anti-spam bot if spam arrives;
   - members may **not** pin messages.
3. Admins: the moderator (Tech Lead). Add another only after they are a maintainer.
4. Topics (if the group enables Topics): ទូទៅ General · បច្ចេកទេស Dev · ការបកប្រែ Translation · ការសាកល្បង Testing.
5. Pin the message below. Replace the link placeholders when they exist.

**Pinned message** `[km-review]`

> 🩸 **សូមស្វាគមន៍មកកាន់សហគមន៍ ជីវិត — LifeLink KH!**
> ក្រុមនេះសម្រាប់អ្នកដែលចង់ជួយកែលម្អកម្មវិធីភ្ជាប់អ្នកបរិច្ចាគឈាម៖ សំណួរ ដំណឹង ការសាកល្បង និងការបកប្រែ។
>
> 📌 ច្បាប់៖
> 1. គោរពគ្នាទៅវិញទៅមក (ក្រមសីលធម៌៖ github.com/NemSothea/LifeLinkKh/blob/feat/firebase-backend/CODE_OF_CONDUCT.md)
> 2. **កុំបង្ហោះព័ត៌មានផ្ទាល់ខ្លួន** (ឈ្មោះ លេខទូរស័ព្ទ ក្រុមឈាម ទីតាំង) របស់នរណាម្នាក់
> 3. បញ្ហា (bug) និងគំនិតថ្មី សូមដាក់នៅ GitHub Issues ដើម្បីកុំឲ្យបាត់
> 4. **ក្រុមនេះមិនមែនជាខ្សែបន្ទាន់ទេ** បើត្រូវការឈាមបន្ទាន់ សូមប្រើកម្មវិធី ឬទាក់ទងមន្ទីរពេទ្យ / មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម
>
> 🇬🇧 **Welcome to the LifeLink KH community!** Questions, news, testing and translation for the
> blood-donor app. Khmer first, English welcome. Be kind; never post anyone's personal data;
> bugs go to GitHub Issues; this is **not** an emergency line.
>
> 📱 App: https://lifelinkkh.vercel.app/km/download · 💻 Code: https://github.com/NemSothea/LifeLinkKh ·
> 🤝 Contribute: CONTRIBUTING.km.md

---

## Facebook page: setup (human)

1. Create a **Page**: name **"LifeLink KH · ជីវិត"**, category *Nonprofit organization* or
   *Community*. Don't impersonate a hospital or the NBTC; the About text says who runs it.
2. About (short) `[km-review]`: "កម្មវិធីឥតគិតថ្លៃ ភ្ជាប់អ្នកបរិច្ចាគឈាមស្ម័គ្រចិត្ត ជាមួយគ្រួសារដែលត្រូវការឈាមបន្ទាន់។ គម្រោងសហគមន៍ open source។ ·
   A free app connecting voluntary blood donors with families who urgently need blood. Open-source community project."
3. Website field: `https://lifelinkkh.vercel.app/km`. Add the GitHub link in the About section.
4. Profile picture: the flat red LifeLink icon (`frontend/src/app/icon.png`). Cover image: a
   showcase-seed screenshot from `docs/assets/screens/` (no real data).
5. Page roles: the moderator is admin. Anyone else posting is an editor only after they are a maintainer.
6. Turn on the profanity filter (medium). Reply to messages with a pointer to GitHub or the app;
   **never collect health data in Messenger**.
7. First post: the launch copy in `docs/community/launch-posts.md` (Phase 6).

---

## Moderation

| Situation | Action |
|---|---|
| Someone posts personal data (their own or another's) | Delete it within the hour and message the poster privately. If it's someone else's data, record the incident privately. |
| Urgent blood request in chat | Reply once, kindly: app, hospital, NBTC. Don't relay it. |
| Spam or scam (including "paid blood" offers; DEC-019 notes brokers exist) | Delete and ban. Pin a warning that LifeLink never asks for money. |
| Harassment | Follow [`CODE_OF_CONDUCT.md`](../../CODE_OF_CONDUCT.md) enforcement guidelines. |
| Bug report in chat | Open a GitHub issue and reply with its link. |
| Security issue in chat | Ask them to delete the post and use `SECURITY.md`. |
