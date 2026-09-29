# Does LifeLink KH help real Cambodian donors and families?

**Research report · 2026-09-29 · PO research, no code changed.** Written for Sothea (Tech Lead / PO, six-time donor) and the team.

Every claim about Cambodia, blood exchange or medicine carries a source number from §9. `[unverified]` means no reliable source was found. It is a gap, not a guess. Several news sites (Khmer Times, Phnom Penh Post, Cambodia Daily) block direct reading, so news figures come from search summaries of those articles. Treat them as medium confidence. **Before any eligibility or exchange wording ships, confirm it with the NBTC.** Nothing here is medical advice.

---

## 1. Summary

- **Donors: partly.** Matching and alerts work. But the app tells donors they are eligible again after 56 days, and Cambodia's reported practice is 3 months for men and 4 months for women [10][11], in line with WHO's 12 and 16 weeks [1]. A donor following the app is sent back 4–9 weeks early.
- **Requesters (families): partly.** Posting is fast, and admin review (DEC-015) is the right defence against fake requests. But the app assumes a stranger with a compatible type will save the day. It never explains how Cambodian families actually get blood: roughly three-quarters of units are **replacement donations**, where the family brings donors of any type to the blood bank [3][6][19].
- **Cambodia: partly.** Any new voluntary donor helps, since voluntary donors are only about 21–27% of supply [6]. But nothing in the app turns a one-off helper into a regular donor, which is WHO's main recommendation [22].
- **Blood exchange: support replacement-at-blood-bank guidance only.** In Cambodia a relative of any type already "exchanges" blood by donating into the bank's tested stock, and the bank issues the patient's type [20][3]. A family-to-family swap solves nothing extra. It would also recreate the stranger-to-stranger deals where paid donors and brokers hide [2][7]. Do not build swap matching.
- **Eligibility beyond the cooldown: no.** No pre-check exists for illness, antibiotics, tattoos, pregnancy, dengue or weight [1]. Donors can be turned away after travelling.
- **Trust: partly.** Admin review exists, but a donor cannot see that a request was reviewed. There is no report button, and nowhere says "never pay or accept money", although blood brokers are documented [2][7].
- **Information: partly.** The in-app guide covers eating, ID and timing. It lacks where to donate (NBTC address), the 45 kg minimum, and the 350 ml standard unit [8][10][11]. It also repeats the 56-day rule.
- **Web frontend: no.** The public site shows a board and a download link. It gives families and donors no guidance.
- **Biggest single fix:** the cooldown rule. It is wrong for everyone, and it runs in three places in the code.
- **Biggest product insight:** a family's most common need is "N donors of any type for replacement", not "a donor of type X". The request model cannot say that today.

## 2. How blood donation works in Cambodia

**Structure.** The National Blood Transfusion Center (NBTC) in Phnom Penh reports to the Ministry of Health. It is backed by 21 provincial blood transfusion centres, four of them regional hubs (Kampong Cham, Siem Reap, Battambang, Takeo) [3]. Some NGO hospitals run their own blood banks, such as Kantha Bopha and Angkor Hospital for Children [3][4][5]. The NBTC is on Yothapol Khemarak Phoumin Blvd (St 271 at St 187), next to Khmer-Soviet Friendship Hospital, and takes walk-ins [11][10]. Its opening hours are `[unverified]`.

**Policy.** Since 2003 the national policy has been voluntary, unpaid donation. Blood "will not constitute a source of profit", and only a service charge is allowed, "not for the blood". Blood given freely "should be provided free to the recipient" [2].

**Reality: replacement dominates.**

| Period | Voluntary | Replacement | Source |
|---|---|---|---|
| 2015 / 2016 / 2017 | 34% / 28% / 25.7% | rest | [3] |
| Jan–May 2024 | 10,171 units (~21%) | 37,755 units | [6] |
| Jan–May 2025 | 14,870 units (~27%) | 40,862 units | [6] |
| Jun 2025, NBTC director | ~20% | ~80% | [19] |

Hospitals tell patients they need blood, and "it becomes the responsibility of the family to source the required blood units" [3]. Family and friends donate at the blood centre, and the patient receives units according to how many people donated [20].

**Money.** Officially, blood is free and only a service fee applies [2]. Current fees at public hospitals are `[unverified]`. A Phnom Penh Post report describes a broker outside the NBTC charging about $70 per unit, of which about $15 went to the donor. The article's date is unconfirmed [7]. The 2003 policy itself says the shortage "fuelled a marketing of blood through paid or 'professional' donors … undercover in the group of family" donors [2]. No Cambodian law explicitly bans selling blood was found [7][33] `[low confidence]`.

**Pressure points.**
- **Khmer New Year:** on 6 Apr 2022 the NBTC reported stocks at 50% before the holiday road-accident peak [13].
- **Dengue season:** it drains stock [4]. In Aug 2026 Angkor Hospital for Children made an urgent appeal, with 40,915 dengue cases and 58 deaths nationally up to July [5].
- **Demand:** the NBTC says the country needs a unit of blood every five minutes [15].
- **Rare types:** O-negative is reported at about 0.3% of the population [17] `[low confidence]`. No peer-reviewed RhD-negative figure for Khmer people was found `[unverified]`.

**How donors are found today.** Kantha Bopha uses Telegram groups of staff, families and volunteers [4]. The NBTC posts appeals on Facebook as "Cambodia Blood Service" [14]. Families posting on Facebook is widely described, but no study measures it `[unverified as quantified]`.

## 3. Eligibility: Cambodia vs this app

| Rule | Cambodian value | WHO 2012 | App today | Match? | Source |
|---|---|---|---|---|---|
| Interval, men | 3 months | 12 weeks (84 days) | 56 days for everyone | **No** | [10][11][1] |
| Interval, women | 4 months | 16 weeks (112 days) | 56 days for everyone | **No** | [10][11][1] |
| Age | 18–60 (some sources say 17–60) | usually 18–65 | not asked | **No check** | [8][9][10][1] |
| Minimum weight | 45 kg | 45 kg for 350 ml, 50 kg for 450 ml | not asked | **No check** | [8][9][10][1] |
| Standard unit | 350 ml | — | not mentioned | n/a | [10][11] |
| Haemoglobin | `[unverified]` | ≥12.0 g/dL women, ≥13.0 g/dL men | tested at the centre | n/a | [1] |
| Blood-borne infection | permanent deferral | permanent for HIV and HCV | not mentioned | **No check** | [8][1] |

**Verdict on 56 days: it does not match.** Fifty-six days is the US (FDA/AABB) whole-blood interval. WHO lists it as the shortest interval used anywhere [1]. Cambodia's reported 3 and 4 months agree with WHO's 12 and 16 weeks. The app needs one interval for men and one for women: at least 84 and 112 days, or 90 and 120 to match "3 and 4 months". The NBTC should confirm the exact numbers, since no primary NBTC document was found online.

**Temporary deferrals a donor can check at home** (WHO 2012; Cambodian periods are `[unverified]`) [1]:

| Condition | Wait |
|---|---|
| Fever or minor illness | 14 days after recovery |
| Antibiotics | 14 days after the last dose |
| Aspirin | 5 days (matters for platelets) |
| Other anti-inflammatories | 48 hours |
| Dengue | 6 months after full recovery (endemic areas) |
| Malaria | 6 months after treatment and recovery |
| Tattoo, piercing, acupuncture | 12 months |
| Pregnancy or breastfeeding | throughout, plus 6 months |
| Major surgery or a transfusion received | 12 months |
| Tooth extraction | 7 days |
| Flu vaccine | 48 hours |

Also: have a meal or snack and drink water in the four hours before [1]. The centre tests haemoglobin, blood pressure and infection markers, which cannot be checked at home [1][10]. Travel deferrals are a rule for foreign blood services about visitors to Cambodia, not for residents [12].

## 4. Blood exchange

**The situation.** The patient needs A. The relatives are B or O. Can they "exchange"?

**Replacement at the blood bank: yes, and it is the norm.** Relatives donate at the NBTC or the hospital blood bank. Their units go into tested stock regardless of type, and the bank issues the patient's type from stock [20][3][21]. Mandatory screening for HIV, hepatitis B and syphilis has applied since 1991, and hepatitis C since 1996 [2].
- **Required?** In practice it is expected: the family is "responsible" for sourcing units [3][19]. No published rule makes it mandatory `[unverified]`. Kantha Bopha accepts replacement donors and appeals to families when stock is low [4].
- **Individual Phnom Penh hospitals** (Calmette, Khmer-Soviet, Preah Kossamak): their rules are `[unverified]`.
- **Fee:** blood is free by policy and only a service charge applies [2]. Current amounts are `[unverified]`.

**Swap between two families: no evidence it happens, and no need for it.** No Cambodian source describes, allows or forbids it `[unverified]`. It adds nothing, because family 1's B donor already earns A units from stock. It would create a named donor, a known recipient and a deal between strangers. That is exactly where Cambodian policy found paid "professional" donors hiding [2], and where brokers operate [7].

**WHO and ISBT positions.**
- **WHO/IFRC 2010:** the goal is to "phase out family/replacement blood donation and eliminate paid donation", partly by converting family donors into regular voluntary donors [22].
- **Melbourne Declaration:** it calls family replacement and paid donation "less safe" [23].
- **WHA63.12:** it asks for self-sufficiency based on voluntary unpaid donation [24].
- **Global picture:** worldwide, 15.9% of donations are family or replacement. In 56 countries they are more than half of supply [25].
- **ISBT:** its Code of Ethics requires informed consent, and keeps donor and recipient anonymous to each other unless both freely agree otherwise [26].
- **Infection rates:** replacement donors carry more infection markers in study after study. One example is 5.05% vs 2.36% overall in India [27][28][29]. Cambodia's own policy says paid donors hiding among family donors were "several times more likely" to carry HIV, syphilis or hepatitis C [2].

**Directed donation (a relative's unit going straight to the patient).** No Cambodian policy for it was found `[unverified]`. Blood from close relatives raises the risk of transfusion-associated graft-versus-host disease, which is nearly always fatal, unless the unit is irradiated [30][31][32]. Whether Cambodian centres can irradiate is `[unverified]`. That is the hospital's decision, never the app's.

**Safeguards any exchange feature would need:**
- Donations go into stock, never paired person to person.
- No money, prices, rewards or open chat between strangers.
- A request is never blocked because the family has not brought donors.
- Each donor consents on their own device, and nobody nags relatives.
- An invitation to become a regular voluntary donor afterwards.
- Abuse reporting and an audit trail [2][7][22][26].

**Conclusion: support replacement-at-blood-bank guidance only.** It matches how about three-quarters of Cambodian blood is actually collected, and it fully solves the wrong-type-relatives case. Swap matching solves nothing extra, invites brokers, and runs against WHO and ISBT direction. Doing neither would ignore how Cambodians actually get blood.

## 5. The three journeys today in Phnom Penh

**A. First-time donor.**
1. Sees a Facebook or Telegram appeal [4][14], or a drive at a hospital or office [13][35].
2. ⚠ Doesn't know whether they qualify: 45 kg, age, a recent fever or antibiotics, a tattoo [1][8].
3. ⚠ Doesn't know where to go or the NBTC's hours `[unverified]`, or whether to bring ID `[unverified]`.
4. At the centre: registration, questionnaire, weight, blood pressure, haemoglobin. ⛔ Deferred on the spot if anything fails [1].
5. Donates 350 ml in about 10 minutes, with the visit about 45 minutes in total [10][34]. Gets food and drink, learns their blood type, and gets free confidential screening for HIV and hepatitis [10][15].
6. ⚠ Nobody reminds them when they can give again, and many never return. That is why voluntary donation stays near 25% [3][6].

**B. Repeat donor (like the owner).**
1. Knows the routine and roughly when they last gave.
2. ⚠ Uses the app, which says they can donate again after 56 days. ⛔ The centre defers them if they come before 3 months (men) or 4 months (women) [10][11].
3. ⚠ Gets alerts for "type X at hospital Y". Doesn't know whether to go to the hospital, the NBTC, or the hospital's blood bank.
4. ⚠ Can't tell whether a request is real or a pretext to ask for money [7][18].

**C. A family at a hospital whose relatives are the wrong type.**
1. A doctor says the patient needs 2 units of A. ⚠ Often told to "find donors", without being told any type works for replacement [3][20].
2. ⚠ Relatives are B and O. They assume they are useless and post on Facebook asking for A.
3. ⚠ Brokers may approach and ask for about $70 per unit [7]. ⛔ Nobody tells them blood is free by policy [2].
4. ⚠ They may try to arrange a relative's blood going directly to the patient, not knowing the graft-versus-host risk [30].
5. If a stranger responds, the family can't tell whether that person is a volunteer or a paid donor [2].

## 6. Gap analysis: this app, mobile and web

| Journey step | Gap | Where in the app | Evidence |
|---|---|---|---|
| B2 | Cooldown is 56 days for everyone; Cambodia uses 3 months (men) and 4 months (women) | `mobile/lib/src/features/donor/domain/eligibility.dart` (`cooldownDays`), `frontend/src/server/matching.js` and `confirm-donation.js` (`COOLDOWN_DAYS`) | [1][10][11] |
| B2 | No sex field, so no interval per sex is possible | `mobile/lib/src/features/donor/domain/donor_profile.dart`, donor setup screen | [1] |
| B2 | Guide copy says "donate again after 56 days" | `mobile/lib/l10n/app_en.arb` `donateGuideNextCooldown` (and the Khmer file) | [10][11] |
| A2 | No pre-check before accepting: weight, age, illness, antibiotics, tattoo, pregnancy, dengue, malaria, surgery | Match detail accept flow, `match_detail_screen.dart` | [1] |
| A3 | Guide lacks the NBTC address and phone, the 45 kg minimum, the 350 ml unit, and "have a meal or snack in the last 4 hours" | `donation_guide_screen.dart` | [1][8][10][11] |
| A6 | Nothing invites a one-off donor to become a regular donor, and no eligibility reminder push exists (`FR-NOTIFY-002` deferred) | Donation history and Home | [22][3] |
| B3 | Accepted-state screen says "go to hospital" with no blood-bank location, phone or hours | `match_detail_screen.dart`; `hospital.dart` has no contact or blood-bank fields | `[unverified]` hospital blood-bank data |
| B4 | Donor never sees that an admin reviewed the request | Match detail and Home request tiles | DEC-015 |
| B4 / C3 | No "LifeLink never asks for money. Never pay or accept payment for blood." | Request form, match detail, public board | [2][7] |
| B4 | No way to report a suspicious request or requester | Match detail, request detail | [18] |
| C1–C2 | Request form asks for a specific type only; it can't say "we need replacement donors of any type" | `request_form_screen.dart`; `frontend/src/server/matching.js` (`COMPATIBLE_DONORS`) | [3][20] |
| C1–C2 | No family guidance on how getting blood works: replacement at the blood bank, any type counts, blood is free, and the service fee | Request form, request detail, web landing page | [2][3][20] |
| C4 | No warning about direct relative-to-patient transfusion | Family guidance (new) | [30][32] |
| C | Zero matches only says "none found"; it could point the family to replacement at the blood bank (`FR-MATCH-002` deferred) | Request detail, `noMatches` | [3][20] |
| All | Admin review hours not published, although DEC-015 itself says to publish them before launch | Request form confirm dialog | DEC-015 |
| All | Web site gives no donor or family guidance, only a board and a download link | `frontend/src/app/[locale]/page.tsx`, `portal/page.tsx` | [2][3] |

## 7. Recommendations

Ranked by impact on a real Cambodian user, divided by build effort.

| # | Change | Type | Helps | Effort | Conflicts |
|---|---|---|---|---|---|
| 1 | Replace the 56-day rule with intervals per sex (84/112 or 90/120 days, as NBTC confirms), in all three places, with tests at each boundary | Data/rule | Donors | M | PRD FR-03 and FR-09, `FR-DONOR-002`; adds sensitive data (sex), so update the privacy page |
| 2 | Add "LifeLink never asks for money. Never pay or accept payment for blood. Blood is free by national policy." on the request form, match detail, accepted state and web board | Copy | Everyone | S | none |
| 3 | Add a "How getting blood works" page for families, in the app and on the web: replacement donors of **any** type at the blood bank, free by policy, a service fee may apply, never pay a broker, don't arrange direct relative transfusion | Copy/UI | Requesters | S | none; needs NBTC wording check and a native Khmer check |
| 4 | Rewrite the zero-match and pending screens to point families to replacement at the blood bank | Copy/UI | Requesters | S | partly covers deferred `FR-MATCH-002` |
| 5 | Add a pre-donation self-check before Accept: 6–8 yes/no questions from §3. Any "yes" shows "you may be deferred, check with the centre" and never blocks | UI | Donors | M | none; informational only |
| 6 | Show a "Reviewed by LifeLink" badge on approved requests, and publish the admin review hours | UI/copy | Donors, requesters | S | none; completes DEC-015 |
| 7 | Add a "Report this request" action that goes to the admin queue | UI/data | Everyone | M | touches Firestore rules; DEC-014 means the admin is the only reviewer |
| 8 | Donation guide: add the NBTC address and phone, 45 kg, 350 ml, "meal or snack in the last 4 hours", about 45 minutes in total; fix the cooldown line | Copy | Donors | S | none; NBTC hours `[unverified]` |
| 9 | Add a request kind: "specific type needed" (today) vs "replacement donors, any type". The second alerts all eligible donors nearby and sends them to the blood bank, not to the patient | Data/rule | Requesters, Cambodia | L | ADR 0004 and `FR-MATCH-001` assume type compatibility; needs an ADR and NBTC confirmation |
| 10 | After a confirmed donation, invite the donor to become a regular donor and show their next eligible date; build the deferred eligibility reminder push | UI/data | Cambodia | M | `FR-NOTIFY-002` deferred by DEC-004 |
| 11 | Store the blood-bank location, phone and hours on each hospital record, and show them in the accepted state | Data | Donors | M | seed data only |
| 12 | Partner with the NBTC or a hospital as a second reviewer and verified source of requests | Process | Everyone | L | DEC-014 (admin-only v1); a v2 role |
| — | **Do not build** family-to-family swap matching | — | — | — | §4 |

## 8. Open questions for the owner

Answer these from your six donations. They decide recommendations 1, 3, 5, 8 and 9.

1. How long did the NBTC or the centre make you wait between donations? Did anyone mention 3 or 4 months?
2. Were you ever deferred, and why? For example weight, haemoglobin, illness or sleep.
3. Where did you donate each time: the NBTC, a hospital blood bank, or a mobile drive? Was any of them for a specific patient?
4. Did a hospital ever ask your family, or a friend's family, to bring replacement donors? Did anyone say any blood type counts?
5. Were you, or anyone you know, ever asked to pay for blood, or offered money to donate?
6. What did you have to bring or show, such as an ID card? Did you get a donor card or your test results?
7. How long did a whole visit take, from arriving to leaving?
8. Would you tick a short "am I eligible today?" checklist before tapping Accept, or would it annoy you in an emergency?

## 9. Sources

Accessed 2026-09-29. "News" marks journalism, not official policy.

1. Blood donor selection: guidelines on assessing donor suitability for blood donation (2012). WHO. https://iris.who.int/server/api/core/bitstreams/440f386c-facc-4ac1-85d4-6a1775d9469c/content
2. National Blood Policy and Priority Strategies 2003–2007. Kingdom of Cambodia, Ministry of Health / NBTS (hosted by WHO). https://cdn.who.int/media/docs/default-source/biologicals/blood-products/document-migration/cambodianationalbloodpolicy2003_2007.pdf
3. PEPFAR Cambodia Blood Safety Program 2013–2018, final report. AIHA / CDC. https://www.aiha.com/wp-content/uploads/2018/10/AIHA-GH000861-CDC-Blood-Safety-Final-Report_Cambodia.pdf
4. The value of blood: the Kantha Bopha hospital blood bank. Beat Richner / Kantha Bopha Foundation. https://www.beat-richner.ch/en/post/the-value-of-blood-the-kantha-bopha-hospital-blood-bank
5. Angkor Hospital for Children seeks urgent blood donations amid rising dengue cases. Cambodianess (news, 16 Aug 2026). https://www.cambodianess.com/article/angkor-hospital-for-children-seeks-urgent-blood-donations-amid-rising-dengue-cases
6. NBTC records rise in blood donations in first five months. Khmer Times (news, 2025). https://www.khmertimeskh.com/501697552/nbtc-records-rise-in-blood-donations-in-first-five-months/
7. Blood money. Phnom Penh Post (news, date unconfirmed). https://phnompenhpost.com/national/blood-money/
8. Give Blood in Cambodia. VOICE (NGO). https://www.voice.org.au/giveblood
9. Donating blood as a positive voluntourism option. ChildSafe Movement. https://thinkchildsafe.org/positive-voluntourism/
10. Public awareness of blood donation (Khmer). RFA Khmer (news, 13 Oct 2013, quoting the NBTC director). https://www.rfa.org/khmer/news/health/public-awareness-of-blood-donation-10132013030716.html
11. New blood bank looks to stock up for national needs. B2B Cambodia (news, 14 Oct 2016). https://b2b-asianews.com/articles/new-blood-bank-looks-to-stock-up-for-national-needs/
12. Cambodia travel deferral FAQ. Finnish Red Cross Blood Service. https://www.veripalvelu.fi/en/faq/cambodia/
13. Khmer New Year's blood stocks only at 50%: NBTC. Phnom Penh Post (news, 6 Apr 2022). https://phnompenhpost.com/national/khmer-new-years-blood-stocks-only-50-nbtc
14. Shortage in blood donors caused by C-19. Khmer Times (news). https://www.khmertimeskh.com/50747087/shortage-in-blood-donors-caused-by-c-19/ ; Cambodia Blood Service (NBTC Facebook page). https://www.facebook.com/cambodiabloodservice/
15. Cambodia urgently needs a unit of blood every five minutes, officials plead. Khmer Times (news, 2 Jul 2025). https://www.khmertimeskh.com/501710466/cambodia-urgently-needs-a-unit-of-blood-every-five-minutes-officials-plead/
16. NBTC appeals to public for blood donations. Khmer Times (news, date unconfirmed). https://www.khmertimeskh.com/501411305/nbtc-appeals-to-public-for-blood-donations/
17. Thirsty for Blood. Southeast Asia Globe (news). https://southeastasiaglobe.com/blood-donation-cambodia/
18. Hospital uncovers FB scam using patients' photos to solicit funds. Khmer Times (news). https://www.khmertimeskh.com/501344208/hospital-uncovers-fb-scam-using-patients-photos-to-solicit-funds/
19. Senior official encourages citizens to donate more blood (Khmer). Kampuchea Thmey (news, 10 Jun 2025). https://www.kampucheathmey.com/health/928977
20. Patients and the Will to Survive in Cambodia. Japan Heart. https://www.japanheart.org/en/en-topics/en-activity-report/cambodia-patients-and-the-will-to-survive-in-cambodia.html
21. Donating Blood to a Specific Patient. Memorial Sloan Kettering Cancer Center. https://www.mskcc.org/about/get-involved/donating-blood/faqs-donating-blood-platelets/donating-blood-specific-patient
22. Towards 100% voluntary blood donation: a global framework for action (2010). WHO / IFRC. https://www.ncbi.nlm.nih.gov/books/NBK305663/
23. The Melbourne Declaration on 100% Voluntary Non-remunerated Donation of Blood (2009). WHO. https://www.who.int/publications/m/item/the-melbourne-declaration
24. WHA63.12 Availability, safety and quality of blood products (2010). WHO. https://apps.who.int/gb/ebwha/pdf_files/wha63/a63_r12-en.pdf
25. Global status report on blood safety and availability 2021. WHO. https://www.who.int/publications/i/item/9789240051683
26. ISBT Code of Ethics (2017). International Society of Blood Transfusion. https://www.isbtweb.org/resources/isbt-code-of-ethics.html
27. Seroprevalence of transfusion-transmitted infections in voluntary and replacement donors: a five-year study. IP Journal of Diagnostic Pathology and Oncology. https://jdpo.org/archive/volume/3/issue/3/article/2488
28. Seroprevalence of TTIs among replacement and voluntary donors in a tertiary care hospital. PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC5389209/
29. Safety of family replacement vs voluntary donors in an Egyptian population. PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC4039696/
30. Risk of transfusion-associated GVHD as a result of directed donations from relatives. PubMed. https://pubmed.ncbi.nlm.nih.gov/1519336/
31. Transfusion-associated graft-versus-host disease: a concise review. PMC. https://pmc.ncbi.nlm.nih.gov/articles/PMC6240831/
32. Irradiated blood components. Australian Red Cross Lifeblood. https://www.lifeblood.com.au/health-professionals/products/blood-components/modifications/irradiated
33. Black Market for Blood Raises Safety Concerns. Cambodia Daily (news; page returned 404, read via search summary). https://english.cambodiadaily.com/news/black-market-for-blood-raises-safety-concerns-50567/
34. Donating Blood in Cambodia: My Experience. Epic Travel Plans (blog, low confidence). https://www.epictravelplans.com/donating-blood-siem-reap-cambodia/
35. National Blood Transfusion Center news tag. Open Development Cambodia. https://opendevelopmentcambodia.net/tag/national-blood-transfusion-center-nbtc/
