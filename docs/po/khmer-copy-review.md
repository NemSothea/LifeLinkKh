# Khmer copy review (DEC-019 and the UI work of 2026-09-29)

**For:** Sothea, or any native Khmer speaker. **Why:** every string below was written by Claude, which is not a native speaker. The first drafts had literal translations and wrong words, and this revision fixes the ones Claude could identify. It is still not proof-read.

**How to use:** read the *Now* column on a phone screen if you can. Write your fix in *Correction* and leave it blank if the text is fine. Rows marked **Check** are the ones Claude is least sure of.

## Terms used

| Meaning | App | Web | Note |
|---|---|---|---|
| Blood type | ក្រុមឈាម | ប្រភេទឈាម | Each matches what that client already used. **Check:** pick one for both? |
| Request | ការស្នើសុំ | សំណើ | Same reason. |
| Free of charge | ឥតគិតថ្លៃ | ឥតគិតថ្លៃ | Was មិនគិតថ្លៃ in the first draft. |
| Blood centre | មជ្ឈមណ្ឌលផ្តល់ឈាម | មជ្ឈមណ្ឌលផ្តល់ឈាម | NBTC = មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម. |
| Blood bank | ផ្នែកផ្តល់ឈាម | ផ្នែកផ្តល់ឈាម | Chosen by Sothea 2026-09-29. ធនាគារឈាម was a literal "blood bank" and read as a money bank. |
| Admin | អ្នកគ្រប់គ្រង | អ្នកគ្រប់គ្រង | |
| Give / let | ឲ្យ | ឲ្យ | The older spelling. **Check:** switch to ឱ្យ (MoEYS)? |

## App strings (`mobile/lib/l10n/app_km.arb`)

| Key | English | First draft | Now | Note | Correction |
|---|---|---|---|---|---|
| `donateGuideBeforeMeal` | Have a proper meal or snack in the 4 hours before, and drink plenty of water. | ញ៉ាំអាហារ ឬអាហារសម្រន់ក្នុងរយៈពេល ៤ ម៉ោងមុន ហើយផឹកទឹកឲ្យបានច្រើន។ | ញ៉ាំអាហារ ឬអាហារសម្រន់ក្នុងរយៈពេល ៤ ម៉ោងមុនពេលបរិច្ចាគ ហើយផឹកទឹកឲ្យបានច្រើន។ |  | |
| `donateGuideDuringTime` | A standard donation in Cambodia is 350 ml. The draw takes about 10 minutes, and the whole visit is usually under an hour. | ការបរិច្ចាគស្តង់ដារនៅកម្ពុជាគឺ ៣៥០ មីលីលីត្រ។ ការបូមឈាមចំណាយពេលប្រហែល ១០ នាទី ហើយការមកទាំងមូលជាធម្មតាតិចជាងមួយម៉ោង។ | ជាធម្មតា ឈាមដែលបរិច្ចាគម្តងនៅកម្ពុជាគឺ ៣៥០ មីលីលីត្រ។ ការបូមឈាមចំណាយពេលប្រហែល ១០ នាទី ហើយការមកបរិច្ចាគម្តងៗ ជាធម្មតាមិនដល់មួយម៉ោងទេ។ |  | |
| `donateGuideNextCooldown` | LifeLink counts 3 months (90 days) for men and 4 months (120 days) for women from your last donation, as blood centres in Cambodia do. The centre makes the final check. | LifeLink រាប់ ៣ ខែ (៩០ ថ្ងៃ) សម្រាប់បុរស និង ៤ ខែ (១២០ ថ្ងៃ) សម្រាប់ស្ត្រី ចាប់ពីការបរិច្ចាគចុងក្រោយរបស់អ្នក ដូចមជ្ឈមណ្ឌលឈាមនៅកម្ពុជា។ មជ្ឈមណ្ឌលជាអ្នកពិនិត្យចុងក្រោយ។ | LifeLink រាប់ ៣ ខែ (៩០ ថ្ងៃ) សម្រាប់បុរស និង ៤ ខែ (១២០ ថ្ងៃ) សម្រាប់ស្ត្រី គិតពីថ្ងៃបរិច្ចាគចុងក្រោយ ដូចមជ្ឈមណ្ឌលផ្តល់ឈាមនៅកម្ពុជាអនុវត្ត។ បុគ្គលិកមជ្ឈមណ្ឌលជាអ្នកសម្រេចចុងក្រោយ។ |  | |
| `donateGuideBeforeWeight` | You need to weigh at least 45 kg and usually be 18 to 60 years old. | *(same)* | អ្នកត្រូវមានទម្ងន់យ៉ាងតិច ៤៥ គីឡូក្រាម ហើយជាធម្មតាមានអាយុពី ១៨ ដល់ ៦០ ឆ្នាំ។ |  | |
| `donateGuideWaitTitle` | Wait before donating if you… | រង់ចាំសិន មុនពេលបរិច្ចាគ ប្រសិនបើអ្នក… | សូមរង់ចាំសិន កុំទាន់បរិច្ចាគ ប្រសិនបើអ្នក… |  | |
| `donateGuideWaitFever` | had a fever or felt ill in the last 2 weeks | មានគ្រុនក្តៅ ឬមិនស្រួលខ្លួន ក្នុងរយៈពេល ២ សប្តាហ៍ចុងក្រោយ | មានគ្រុនក្តៅ ឬឈឺ ក្នុងរយៈពេល ២ សប្តាហ៍មុននេះ |  | |
| `donateGuideWaitAntibiotics` | took antibiotics in the last 2 weeks | បានលេបថ្នាំអង់ទីប៊ីយោទិច ក្នុងរយៈពេល ២ សប្តាហ៍ចុងក្រោយ | បានលេបថ្នាំអង់ទីប៊ីយ៉ូទិក ក្នុងរយៈពេល ២ សប្តាហ៍មុននេះ | **Check:** spelling អង់ទីប៊ីយ៉ូទិក (was អង់ទីប៊ីយោទិច). | |
| `donateGuideWaitDengue` | had dengue or malaria in the last 6 months | មានជំងឺគ្រុនឈាម ឬគ្រុនចាញ់ ក្នុងរយៈពេល ៦ ខែចុងក្រោយ | កើតជំងឺគ្រុនឈាម ឬគ្រុនចាញ់ ក្នុងរយៈពេល ៦ ខែមុននេះ |  | |
| `donateGuideWaitTattoo` | got a tattoo, piercing or acupuncture in the last 12 months | បានសាក់ ចោះរាងកាយ ឬចាក់ម្ជុលព្យាបាល ក្នុងរយៈពេល ១២ ខែចុងក្រោយ | បានសាក់ ចោះត្រចៀក ឬចោះលើខ្លួន ឬចាក់ម្ជុលព្យាបាលបែបចិន ក្នុងរយៈពេល ១២ ខែមុននេះ | **Check:** acupuncture as ចាក់ម្ជុលព្យាបាលបែបចិន — is there a more common word? | |
| `donateGuideWaitPregnant` | are pregnant or breastfeeding, or gave birth in the last 6 months | កំពុងមានផ្ទៃពោះ ឬបំបៅកូនដោយទឹកដោះ ឬទើបសម្រាលកូនក្នុងរយៈពេល ៦ ខែចុងក្រោយ | កំពុងមានផ្ទៃពោះ កំពុងបំបៅកូនដោយទឹកដោះ ឬទើបសម្រាលកូនក្នុងរយៈពេល ៦ ខែមុននេះ |  | |
| `donateGuideWaitSurgery` | had surgery or received blood in the last 12 months | បានវះកាត់ ឬទទួលការបញ្ចូលឈាម ក្នុងរយៈពេល ១២ ខែចុងក្រោយ | បានវះកាត់ ឬបានទទួលការបញ្ចូលឈាម ក្នុងរយៈពេល ១២ ខែមុននេះ |  | |
| `donateGuideWaitNote` | Staff at the centre make the final check. If you are not sure, ask them before you donate. | បុគ្គលិកនៅមជ្ឈមណ្ឌលជាអ្នកពិនិត្យចុងក្រោយ។ បើមិនប្រាកដ សូមសួរពួកគេមុនពេលបរិច្ចាគ។ | បុគ្គលិកនៅមជ្ឈមណ្ឌលជាអ្នកពិនិត្យ និងសម្រេចចុងក្រោយ។ បើមិនប្រាកដ សូមសួរពួកគាត់មុនពេលបរិច្ចាគ។ |  | |
| `donateGuideWhereTitle` | Where to donate | កន្លែងបរិច្ចាគ | កន្លែងបរិច្ចាគឈាម |  | |
| `donateGuideWhereNbtc` | National Blood Transfusion Center (NBTC): St 271, next to Khmer-Soviet Friendship Hospital, Phnom Penh. Walk-ins welcome. | មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម (NBTC)៖ ផ្លូវ ២៧១ ជាប់មន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត ភ្នំពេញ។ អាចមកដោយផ្ទាល់បាន។ | មជ្ឈមណ្ឌលជាតិផ្តល់ឈាម (NBTC)៖ ផ្លូវលេខ ២៧១ ក្បែរមន្ទីរពេទ្យមិត្តភាពខ្មែរ-សូវៀត ភ្នំពេញ។ អាចមកបរិច្ចាគដោយផ្ទាល់ ដោយមិនចាំបាច់ណាត់ទុកមុន។ |  | |
| `donateGuideWhereOther` | Hospital blood banks and mobile blood drives also collect blood. Watch the Cambodia Blood Service page for dates. | ធនាគារឈាមរបស់មន្ទីរពេទ្យ និងយុទ្ធនាការបរិច្ចាគឈាមចល័តក៏ប្រមូលឈាមដែរ។ សូមតាមដានទំព័រ Cambodia Blood Service សម្រាប់កាលបរិច្ឆេទ។ | ផ្នែកផ្តល់ឈាមនៅមន្ទីរពេទ្យ និងយុទ្ធនាការបរិច្ចាគឈាមចល័ត ក៏ទទួលការបរិច្ចាគដែរ។ សូមតាមដានទំព័រហ្វេសប៊ុក Cambodia Blood Service ដើម្បីដឹងកាលបរិច្ឆេទ។ |  | |
| `screenFailedTitle` | Something went wrong on this screen | មានបញ្ហាលើអេក្រង់នេះ | អេក្រង់នេះមានបញ្ហា |  | |
| `screenFailedBody` | Go back and try again. If it keeps happening, close the app and open it again. | សូមថយក្រោយ ហើយព្យាយាមម្តងទៀត។ បើនៅតែកើតឡើង សូមបិទកម្មវិធី ហើយបើកវាឡើងវិញ។ | សូមត្រឡប់ក្រោយ ហើយព្យាយាមម្តងទៀត។ បើនៅតែមានបញ្ហា សូមបិទកម្មវិធី រួចបើកម្តងទៀត។ | ថយក្រោយ → ត្រឡប់ក្រោយ, the usual word for going back in an app. | |
| `routeNotFoundTitle` | This page does not exist | *(same)* | រកមិនឃើញទំព័រនេះទេ |  | |
| `routeNotFoundAction` | Go to Home | *(same)* | ទៅទំព័រដើម |  | |
| `bloodGuideCta` | How getting blood works | របៀបទទួលបានឈាម | របៀបរកឈាមសម្រាប់អ្នកជំងឺ | **Check:** title changed from "how to receive blood" to "how to find blood for a patient". | |
| `bloodGuideTitle` | How getting blood works | របៀបទទួលបានឈាម | របៀបរកឈាមសម្រាប់អ្នកជំងឺ |  | |
| `bloodGuideIntro` | In Cambodia, most blood for patients comes from relatives and friends who donate. Here is what your family needs to know. | នៅកម្ពុជា ឈាមភាគច្រើនសម្រាប់អ្នកជំងឺ បានមកពីសាច់ញាតិ និងមិត្តភក្តិដែលបរិច្ចាគ។ នេះជាអ្វីដែលក្រុមគ្រួសាររបស់អ្នកគួរដឹង។ | នៅកម្ពុជា ឈាមភាគច្រើនដែលអ្នកជំងឺទទួលបាន គឺមកពីសាច់ញាតិ និងមិត្តភក្តិដែលមកបរិច្ចាគ។ ខាងក្រោមនេះជាអ្វីដែលក្រុមគ្រួសាររបស់អ្នកគួរដឹង។ |  | |
| `bloodGuideAnyTypeTitle` | Any blood type can help | ក្រុមឈាមណាក៏អាចជួយបាន | ក្រុមឈាមអ្វីក៏អាចជួយបាន |  | |
| `bloodGuideAnyTypeDonate` | Relatives and friends can donate at the hospital's blood bank or at the National Blood Transfusion Center, whatever their blood type. | សាច់ញាតិ និងមិត្តភក្តិអាចបរិច្ចាគនៅធនាគារឈាមរបស់មន្ទីរពេទ្យ ឬនៅមជ្ឈមណ្ឌលជាតិផ្តល់ឈាម ទោះជាមានក្រុមឈាមអ្វីក៏ដោយ។ | សាច់ញាតិ និងមិត្តភក្តិ អាចមកបរិច្ចាគនៅផ្នែកផ្តល់ឈាមរបស់មន្ទីរពេទ្យ ឬនៅមជ្ឈមណ្ឌលជាតិផ្តល់ឈាម ទោះបីមានក្រុមឈាមអ្វីក៏ដោយ។ |  | |
| `bloodGuideAnyTypeStock` | Their blood goes into the tested stock, and the blood bank gives the patient the type they need. | ឈាមរបស់ពួកគេចូលទៅក្នុងស្តុកដែលបានពិនិត្យរួច ហើយធនាគារឈាមផ្តល់ឈាមតាមក្រុមដែលអ្នកជំងឺត្រូវការ។ | ឈាមដែលពួកគាត់បរិច្ចាគ នឹងត្រូវពិនិត្យ និងរក្សាទុកនៅផ្នែកផ្តល់ឈាម។ បន្ទាប់មក ផ្នែកផ្តល់ឈាមនឹងផ្តល់ឈាមក្រុមដែលអ្នកជំងឺត្រូវការ។ | Removed the loanword ស្តុក (stock). | |
| `bloodGuideAnyTypeAsk` | Ask the hospital's blood bank how many donors they need from your family. | សូមសួរធនាគារឈាមរបស់មន្ទីរពេទ្យថា ពួកគេត្រូវការអ្នកបរិច្ចាគប៉ុន្មាននាក់ពីក្រុមគ្រួសាររបស់អ្នក។ | សូមសួរផ្នែកផ្តល់ឈាមរបស់មន្ទីរពេទ្យ ថាត្រូវការអ្នកបរិច្ចាគពីក្រុមគ្រួសាររបស់អ្នកប៉ុន្មាននាក់។ |  | |
| `bloodGuideFreeTitle` | Blood is free | ឈាមមិនគិតថ្លៃ | ឈាមឥតគិតថ្លៃ |  | |
| `bloodGuideFreeFee` | By national policy, blood is free to the patient. The hospital may charge a fee for testing and processing. Ask the hospital how much. | តាមគោលនយោបាយជាតិ ឈាមមិនគិតថ្លៃសម្រាប់អ្នកជំងឺទេ។ មន្ទីរពេទ្យអាចគិតថ្លៃសេវាពិនិត្យ និងរៀបចំឈាម។ សូមសួរមន្ទីរពេទ្យពីតម្លៃ។ | តាមគោលនយោបាយជាតិ អ្នកជំងឺទទួលឈាមដោយឥតគិតថ្លៃ។ មន្ទីរពេទ្យអាចគិតថ្លៃសេវាពិនិត្យ និងរៀបចំឈាម។ សូមសួរមន្ទីរពេទ្យថាត្រូវបង់ប៉ុន្មាន។ |  | |
| `bloodGuideFreeNeverPay` | Never pay anyone for blood or for a donor. If someone offers to sell you blood, tell the hospital. | កុំបង់ប្រាក់ឲ្យនរណាម្នាក់ដើម្បីបានឈាម ឬអ្នកបរិច្ចាគ។ បើមាននរណាម្នាក់ស្នើលក់ឈាមឲ្យអ្នក សូមប្រាប់មន្ទីរពេទ្យ។ | កុំបង់ប្រាក់ឲ្យនរណាម្នាក់ ដើម្បីទិញឈាម ឬជួលអ្នកបរិច្ចាគ។ បើមានគេមកលក់ឈាមឲ្យអ្នក សូមប្រាប់មន្ទីរពេទ្យ។ |  | |
| `bloodGuideRelativeTitle` | Blood from close relatives | ឈាមពីសាច់ញាតិជិតស្និទ្ធ | ឈាមពីសាច់ញាតិបង្កើត |  | |
| `bloodGuideRelativeBody` | Do not arrange for a parent's, child's or sibling's blood to go straight to the patient. Let them donate to the blood bank. The hospital decides how blood from relatives is used. | កុំរៀបចំឲ្យឈាមរបស់ឪពុកម្តាយ កូន ឬបងប្អូនបង្កើត បញ្ចូលទៅអ្នកជំងឺដោយផ្ទាល់។ សូមឲ្យពួកគេបរិច្ចាគទៅធនាគារឈាម។ មន្ទីរពេទ្យជាអ្នកសម្រេចពីរបៀបប្រើឈាមពីសាច់ញាតិ។ | កុំរៀបចំបញ្ចូលឈាមរបស់ឪពុកម្តាយ កូន ឬបងប្អូនបង្កើត ទៅអ្នកជំងឺដោយផ្ទាល់។ សូមឲ្យពួកគាត់បរិច្ចាគទៅផ្នែកផ្តល់ឈាម។ មន្ទីរពេទ្យជាអ្នកសម្រេចពីរបៀបប្រើឈាមពីសាច់ញាតិ។ |  | |
| `bloodGuideAppTitle` | How LifeLink helps | របៀបដែល LifeLink ជួយ | LifeLink ជួយអ្នកយ៉ាងដូចម្តេច |  | |
| `bloodGuideAppReview` | An admin checks your request. Then LifeLink alerts nearby volunteer donors whose blood type fits. | អ្នកគ្រប់គ្រងពិនិត្យការស្នើសុំរបស់អ្នក។ បន្ទាប់មក LifeLink ជូនដំណឹងទៅអ្នកបរិច្ចាគស្ម័គ្រចិត្តនៅជិត ដែលមានក្រុមឈាមត្រូវគ្នា។ | អ្នកគ្រប់គ្រងពិនិត្យការស្នើសុំរបស់អ្នកជាមុនសិន។ បន្ទាប់មក LifeLink ផ្ញើដំណឹងទៅអ្នកបរិច្ចាគស្ម័គ្រចិត្តនៅជិតនោះ ដែលមានក្រុមឈាមត្រូវគ្នា។ |  | |
| `bloodGuideAppDonors` | Donors who accept see your phone number and come to donate at the hospital or blood bank. | *(same)* | អ្នកបរិច្ចាគដែលយល់ព្រម នឹងឃើញលេខទូរស័ព្ទរបស់អ្នក ហើយមកបរិច្ចាគនៅមន្ទីរពេទ្យ ឬផ្នែកផ្តល់ឈាម។ |  | |
| `bloodGuideSource` | Based on Cambodia's national blood policy and WHO guidance. The hospital's blood bank has the final word on its own rules. | ផ្អែកលើគោលនយោបាយជាតិស្តីពីឈាមរបស់កម្ពុជា និងការណែនាំរបស់ WHO។ ធនាគារឈាមរបស់មន្ទីរពេទ្យជាអ្នកសម្រេចចុងក្រោយលើច្បាប់របស់ខ្លួន។ | ផ្អែកលើគោលនយោបាយជាតិស្តីពីឈាមរបស់កម្ពុជា និងការណែនាំរបស់អង្គការសុខភាពពិភពលោក (WHO)។ ផ្នែកផ្តល់ឈាមរបស់មន្ទីរពេទ្យ ជាអ្នកសម្រេចចុងក្រោយតាមគោលការណ៍របស់ខ្លួន។ | ច្បាប់ (law) → គោលការណ៍ (rules). WHO written out. | |
| `moneyNotice` | LifeLink never asks for money. Never pay or accept payment for blood: by national policy, it is free. | LifeLink មិនដែលសុំប្រាក់ទេ។ កុំបង់ ឬទទួលប្រាក់ដើម្បីឈាម៖ តាមគោលនយោបាយជាតិ ឈាមមិនគិតថ្លៃ។ | LifeLink មិនដែលសុំប្រាក់ពីអ្នកទេ។ កុំទិញ ឬលក់ឈាមដាច់ខាត៖ តាមគោលនយោបាយជាតិ ឈាមគឺឥតគិតថ្លៃ។ | Was a literal "pay or accept payment for blood"; now "never buy or sell blood". | |
| `matchReviewedBadge` | Checked by a LifeLink admin | បានពិនិត្យដោយអ្នកគ្រប់គ្រង LifeLink | អ្នកគ្រប់គ្រង LifeLink បានពិនិត្យរួច | Passive voice → active. | |
| `requestNoDonorsTitle` | No matching donor nearby yet | មិនទាន់មានអ្នកបរិច្ចាគត្រូវគ្នានៅជិតទេ | មិនទាន់មានអ្នកបរិច្ចាគត្រូវគ្នានៅជិតនេះទេ |  | |
| `requestNoDonorsBody` | Your relatives and friends can still help. At the hospital's blood bank, a donor of any blood type counts towards the blood your patient needs. | សាច់ញាតិ និងមិត្តភក្តិរបស់អ្នកនៅតែអាចជួយបាន។ នៅធនាគារឈាមរបស់មន្ទីរពេទ្យ អ្នកបរិច្ចាគដែលមានក្រុមឈាមណាក៏ដោយ ត្រូវបានរាប់បញ្ចូលក្នុងឈាមដែលអ្នកជំងឺត្រូវការ។ | សាច់ញាតិ និងមិត្តភក្តិរបស់អ្នកនៅតែអាចជួយបាន។ នៅផ្នែកផ្តល់ឈាមរបស់មន្ទីរពេទ្យ អ្នកបរិច្ចាគមានក្រុមឈាមអ្វីក៏បាន អាចបរិច្ចាគជំនួសឲ្យអ្នកជំងឺរបស់អ្នក។ | Was a literal "counts towards"; now "can donate in place of". | |
| `donorSexLabel` | Sex | *(same)* | ភេទ |  | |
| `donorSexHint` | Blood centres in Cambodia ask men to wait 3 months and women 4 months between donations. LifeLink uses this only to count your wait. If you prefer not to say, it counts 4 months. Only you and the LifeLink admin can see it. | មជ្ឈមណ្ឌលឈាមនៅកម្ពុជាឲ្យបុរសរង់ចាំ ៣ ខែ និងស្ត្រីរង់ចាំ ៤ ខែ រវាងការបរិច្ចាគម្តងៗ។ LifeLink ប្រើព័ត៌មាននេះតែដើម្បីរាប់ពេលរង់ចាំរបស់អ្នកប៉ុណ្ណោះ។ បើអ្នកមិនចង់ប្រាប់ វានឹងរាប់ ៤ ខែ។ មានតែអ្នក និងអ្នកគ្រប់គ្រង LifeLink ទេដែលអាចមើលឃើញ។ | មជ្ឈមណ្ឌលផ្តល់ឈាមនៅកម្ពុជា ឲ្យបុរសរង់ចាំ ៣ ខែ និងស្ត្រីរង់ចាំ ៤ ខែ រវាងការបរិច្ចាគម្តងៗ។ LifeLink ប្រើព័ត៌មាននេះ សម្រាប់តែរាប់ថ្ងៃរង់ចាំរបស់អ្នកប៉ុណ្ណោះ។ បើអ្នកមិនចង់ប្រាប់ LifeLink នឹងរាប់ ៤ ខែ។ មានតែអ្នក និងអ្នកគ្រប់គ្រង LifeLink ទេដែលមើលឃើញព័ត៌មាននេះ។ |  | |
| `donorSexMale` | Male | *(same)* | ប្រុស |  | |
| `donorSexFemale` | Female | *(same)* | ស្រី |  | |
| `donorSexUnspecified` | Prefer not to say | *(same)* | មិនចង់ប្រាប់ |  | |
| `matchCheckTitle` | Before you accept: does any of these apply to you? | មុនពេលយល់ព្រម៖ តើមានចំណុចណាមួយខាងក្រោមត្រូវនឹងអ្នកទេ? | មុនពេលយល់ព្រម៖ តើអ្នកមានករណីណាមួយខាងក្រោមទេ? |  | |
| `matchCheckUnderweight` | weigh less than 45 kg | *(same)* | មានទម្ងន់តិចជាង ៤៥ គីឡូក្រាម |  | |
| `matchCheckWarning` | You may be turned away at the centre. Check with the centre before you go. If you cannot donate, decline instead. | អ្នកអាចនឹងមិនអាចបរិច្ចាគបាននៅមជ្ឈមណ្ឌល។ សូមសួរមជ្ឈមណ្ឌលមុនពេលទៅ។ បើអ្នកមិនអាចបរិច្ចាគបានទេ សូមចុចបដិសេធវិញ។ | មជ្ឈមណ្ឌលប្រហែលជាមិនអនុញ្ញាតឲ្យអ្នកបរិច្ចាគទេ។ សូមសួរមជ្ឈមណ្ឌលមុនពេលធ្វើដំណើរទៅ។ បើអ្នកមិនអាចបរិច្ចាគបាន សូមចុច «បដិសេធ»។ | Removed the doubled អាច…អាច. | |
| `reportCta` | Report this request | រាយការណ៍សំណើនេះ | រាយការណ៍ការស្នើសុំនេះ |  | |
| `reportTitle` | Report this request | រាយការណ៍សំណើនេះ | រាយការណ៍ការស្នើសុំនេះ |  | |
| `reportBody` | Only the LifeLink admin sees your report. The family is not told who sent it. | មានតែអ្នកគ្រប់គ្រង LifeLink ទេដែលឃើញរបាយការណ៍របស់អ្នក។ ក្រុមគ្រួសារមិនដឹងថាអ្នកណាជាអ្នកផ្ញើទេ។ | មានតែអ្នកគ្រប់គ្រង LifeLink ទេដែលឃើញរបាយការណ៍របស់អ្នក។ ក្រុមគ្រួសារមិនដឹងថាអ្នកណាជាអ្នករាយការណ៍ទេ។ |  | |
| `reportReasonMoney` | They asked for money or offered to pay | ពួកគេសុំប្រាក់ ឬស្នើបង់ប្រាក់ | គេសុំប្រាក់ ឬស្នើឲ្យប្រាក់ខ្ញុំ |  | |
| `reportReasonFake` | The request looks fake | សំណើនេះហាក់ដូចជាក្លែងក្លាយ | ការស្នើសុំនេះមើលទៅដូចជាក្លែងក្លាយ |  | |
| `reportReasonHarassment` | I was harassed or threatened | ខ្ញុំត្រូវបានរំខាន ឬគំរាមកំហែង | មានគេរំខាន ឬគំរាមកំហែងខ្ញុំ | Passive calque ត្រូវបានរំខាន → មានគេរំខាន. | |
| `reportReasonOther` | Something else | ផ្សេងទៀត | មូលហេតុផ្សេងទៀត |  | |
| `reportNoteLabel` | What happened? (optional) | តើមានអ្វីកើតឡើង? (ស្រេចចិត្ត) | តើមានរឿងអ្វីកើតឡើង? (មិនបាច់សរសេរក៏បាន) | ស្រេចចិត្ត (optional) → មិនបាច់សរសេរក៏បាន (plainer). | |
| `reportSendCta` | Send report | *(same)* | ផ្ញើរបាយការណ៍ |  | |
| `reportSending` | Sending… | *(same)* | កំពុងផ្ញើ… |  | |
| `reportSent` | Thank you. An admin will look at it. | *(same)* | សូមអរគុណ។ អ្នកគ្រប់គ្រងនឹងពិនិត្យមើល។ |  | |
| `reportFailed` | Could not send the report. Try again. | *(same)* | មិនអាចផ្ញើរបាយការណ៍បានទេ។ សូមព្យាយាមម្តងទៀត។ |  | |
| `reportAlreadySent` | You have already reported this request. | អ្នកបានរាយការណ៍សំណើនេះរួចហើយ។ | អ្នកបានរាយការណ៍ការស្នើសុំនេះរួចហើយ។ |  | |

## Web strings (`frontend/src/messages/km.json`)

The same content as the app's guides, so the same fixes apply: `gettingBlood.*`, `app.guideCard*`, `portal.guideLink`, `portal.moneyNotice`, `portal.report*`, `home.safety[1]` and the privacy lines about sex and reports. Review them on the page at `/km/getting-blood` and `/km/privacy`.

## Not covered

The app's older Khmer strings, which were already there before 2026-09-29, were not reviewed here. They were also machine-written, and some mix terms (ការស្នើសុំ and សំណើ both appear). They need the same pass.
