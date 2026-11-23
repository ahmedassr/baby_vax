# Third-party data, fonts and packages

What Baby Vax ships that it did not write, where it came from, and under
which licence. Keep this in step with `pubspec.yaml` and the generated files
it names.

## WHO Child Growth Standards (growth tracker percentiles)

**Used in:** `lib/app/core/service/growth/who_lms_data.dart` (generated) and
the percentile curves and readings on the growth screens. The test fixture
`test/growth/who_sd_fixture.dart` holds the same tables' published −2 SD,
median and +2 SD columns, used only to check the maths.

**What:** the L (Box-Cox power), M (median) and S (coefficient of variation)
parameters for every whole month of age 0–60, boys and girls, for
weight-for-age, length/height-for-age and head-circumference-for-age.
Length/height: recumbent length 0–23 months, standing height 24–60 months, as
WHO splits its own tables.

**Source:** World Health Organization, *WHO Child Growth Standards*, z-score
tables, birth to 5 years, from
<https://www.who.int/tools/child-growth-standards/standards>. Downloaded in
the v1.1 development session on 11 November 2026 and again on 13 November
2026; both downloads were byte-identical.

| File | URL (cdn.who.int, `…/child-growth/child-growth-standards/indicators/`) | SHA-256 |
| --- | --- | --- |
| wfa_boys.xlsx | `weight-for-age/wfa_boys_0-to-5-years_zscores.xlsx?sfvrsn=97a05331_9` | `f8f5a77b944ff7a8c1524e76f9d33f8a93cc423d23c2e7f2b10ba6b96a428e69` |
| wfa_girls.xlsx | `weight-for-age/wfa_girls_0-to-5-years_zscores.xlsx?sfvrsn=4c03b8db_7` | `01e9a6fda2f3723dbc74d3c86bfbfcb9f6d474367d1d7b4a804501a2debd2ef1` |
| lhfa_boys_0_2.xlsx | `length-height-for-age/lhfa_boys_0-to-2-years_zscores.xlsx?sfvrsn=30e044c_9` | `ccfd8e455141c9a39dd728d99b7d7e080a925b06ea4a4d7592229665713dba54` |
| lhfa_boys_2_5.xlsx | `length-height-for-age/lhfa_boys_2-to-5-years_zscores.xlsx?sfvrsn=17e5ad91_9` | `a44ed06039e0a9dd6920e4a4d928395c541c9732662e49eacd489d2194ccc80d` |
| lhfa_girls_0_2.xlsx | `length-height-for-age/lhfa_girls_0-to-2-years_zscores.xlsx?sfvrsn=e9e66a95_11` | `6757f5eb96b51ab5cdb4828105929c78b1fb3d73b0fd8fa65682ad9f60f8c083` |
| lhfa_girls_2_5.xlsx | `length-height-for-age/lhfa_girls_2-to-5-years_zscores.xlsx?sfvrsn=2ec187b9_11` | `a976c56a6d36885cc32bf77c5539ca066e396ef2adad06011cd71d9eb0f0eb5c` |
| hcfa_boys.xlsx | `head-circumference-for-age/hcfa-boys-0-5-zscores.xlsx?sfvrsn=adf57aa4_8` | `296038a15de807ee74940627bd1ddc638e68b223b410b4ca3ccf1ff4a8b5770a` |
| hcfa_girls.xlsx | `head-circumference-for-age/hcfa-girls-0-5-zscores.xlsx?sfvrsn=8f959f88_6` | `134cd53ca39f0f55b0b3c2bc6c94278c83d9945842bc64088464f73effcd12e7` |

**Regenerate:** put the eight files in one folder and run
`python3 -I tool/who_growth/generate.py <folder> > lib/app/core/service/growth/who_lms_data.dart`
(and `--fixture` > `test/growth/who_sd_fixture.dart` for the test fixture),
then `dart format lib test`. Standard library only.

**Licence:** CC BY-NC-SA 3.0 IGO, WHO's default licence for its publications
(<https://www.who.int/about/policies/publishing/copyright>). Attribution as
required: *WHO Child Growth Standards. Geneva: World Health Organization;
2006. Licence: CC BY-NC-SA 3.0 IGO.* The attribution is also in the growth
screen's footer.

> **Decision for the owner:** the licence is **non-commercial**. Baby Vax is
> free with no ads or purchases, which fits. If the app is ever monetised,
> WHO's written permission is needed for this data (or the growth
> percentiles must be removed).

## WHO Motor Development Study (motor milestones)

**Used in:** `lib/app/core/service/growth/motor_milestones.dart` (the six
windows, pinned with a code comment) and the Milestones half of the Growth
screen, its details screen and the vaccination card; the plain "what
counts" texts are the `Milestone_<id>_criteria` strings in `en.dart` and
`ar.dart`.

**What:** the windows of achievement for six gross motor milestones,
bounded by the 1st and 99th percentiles, in months: sitting without
support 3.8–9.2, standing with assistance 4.8–11.4, hands-and-knees
crawling 5.2–13.5, walking with assistance 5.9–13.7, standing alone
6.9–16.9, walking alone 8.2–17.6. Crawling is optional in the app because
the study excluded the 4.3% of children who never crawled on hands and
knees ("All normal children will eventually reach these milestones within
these windows (except for those few that will not crawl on hands and
knees)").

**Source (windows):** WHO Multicentre Growth Reference Study Group. *WHO
Motor Development Study: Windows of achievement for six gross motor
development milestones.* Acta Paediatrica 2006; Suppl 450: 86–95,
doi:10.1080/08035320500495563, Table II ("Estimated percentiles and mean
(SD) in days and months for the windows of milestone achievement"; months
are days divided by 30.4375). Read in the v1.1 session on 22 November 2026
from WHO's copy:
<https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/motor-development-milestones/who-motor-development-study-windows-of-achievement-for-six-gross-motor-development-milestones.pdf?sfvrsn=3425c1dc_0>.
WHO's one-page table
(<https://cdn.who.int/media/docs/default-source/child-growth/child-growth-standards/indicators/motor-development-milestones/mm_windows_table.pdf?sfvrsn=cb31ec78_5>)
gives 6.0 instead of 5.9 for the start of walking with assistance; every
other value matches. The paper's 5.9 is used.

**Source (what counts):** the MGRS performance criteria, Table 1 of
Wijnhoven TMA, de Onis M, Onyango AW, et al. *Assessment of gross motor
development in the WHO Multicentre Growth Reference Study.* Food and
Nutrition Bulletin 2004; 25(1 Suppl 1): S37–S45 (© 2004 The United Nations
University), the paper the 2006 study cites for its criteria. Read on 22
November 2026 from <https://journals.sagepub.com/doi/pdf/10.1177/15648265040251S106>.
The app states each criterion in its own plain words in both languages,
with attribution; it does not reproduce the table.

**How it was obtained:** the cloud session's network blocked direct
downloads from who.int and cdn.who.int, so the PDFs were read through the
session's web-fetch tool (HTTP 200, `application/pdf`) and the values
transcribed by hand from the text; no file hash could be recorded. The
values are checked by `test/milestones/milestones_test.dart`.

**Licence:** the 2006 paper is © Taylor & Francis on behalf of the Acta
Paediatrica Foundation, published by WHO on its child growth standards
pages; WHO's publications default to CC BY-NC-SA 3.0 IGO. The app uses six
pairs of numbers (facts) with attribution in the app's footer line and
here. The same non-commercial caveat as the growth standards applies.

## WHO guidance used by the Health log

**Used in:** `lib/app/core/service/health/health_guidance.dart` (the fever
thresholds and which logged signs prompt "get medical help now" or "see a
health worker"), the Health tab's "When to get medical help" screen, the
after-vaccination card, the fever line on the Health tab's temperature
chart (`feverArmpitC` and `rectalOffsetC`, cited under the chart; no new
values were added for it), through the `Health_guide_*` and
`Health_after_vaccine_*` strings. The app quotes facts from these sources
in short form; it gives no treatment or dosing advice.

**Sources**, downloaded in the v1.1 development session on 15 November 2026:

| What | URL | SHA-256 |
| --- | --- | --- |
| *Integrated Management of Childhood Illness (IMCI): Chart Booklet*, WHO, March 2014 (PDF, 76 pages) | <https://cdn.who.int/media/docs/default-source/mca-documents/child/imci-integrated-management-of-childhood-illness/imci-in-service-training/imci-chart-booklet.pdf> | `d10fd1d040bdbdb6db4254b8095e1d1722d0a3d2f80c3651b3003301a8a6959f` |
| *Vaccines and immunization: Vaccine safety*, WHO Questions and answers (English) | <https://www.who.int/news-room/questions-and-answers/item/vaccines-and-immunization-vaccine-safety> | `25f1280921b6d93e96cbd0d36403dc842901151e326e26444ba553c3ca593e55` |
| The same page in WHO's Arabic | <https://www.who.int/ar/news-room/questions-and-answers/item/vaccines-and-immunization-vaccine-safety> | `563eb497fdfcb09f18cf89efdce707d4322a13d348e664e9ab55c4095ac5ad2e` |

(The HTML pages change with WHO's site template; their hashes identify the
copies read, not the text alone. CDC pages were not reachable from the
development environment — Akamai "Access Denied" — so none are used.)

**Facts taken, with where:**

- *Fever* is a temperature of **37.5 °C or above**; the figures are for
  **armpit (axillary)** readings, and rectal readings are about **0.5 °C
  higher** — IMCI chart booklet, "Does the child have fever?" (page 4 of
  76, and its footnote; page numbers are the booklet's own "Page n of 76"), and "Check for very severe disease…" (page 41).
- *Young infant, up to 2 months*: any of not feeding well, convulsions,
  fast breathing (60 a minute or more), severe chest indrawing, **fever
  37.5 °C or above**, **low body temperature below 35.5 °C**, or movement
  only when stimulated / no movement → very severe disease, refer
  **urgently** — page 41.
- *General danger signs* (child 2 months to 5 years): not able to drink or
  breastfeed, vomits everything, has had convulsions, lethargic or
  unconscious, convulsing now → needs **urgent** attention — page 1 ("Check
  for general danger signs").
- *When to return immediately*, sick child: not able to drink or
  breastfeed, becomes sicker, develops a fever; with cough or cold also
  fast or difficult breathing; with diarrhoea also blood in stool or
  drinking poorly — "When to return immediately", page 39. Young infant: breastfeeding
  poorly, reduced activity, becomes sicker, develops a fever, feels
  unusually cold, fast breathing, difficult breathing, palms and soles
  appear yellow — "When to return immediately", page 51.
- *After vaccination*: side effects are usually very minor and of short
  duration, such as a sore arm or a mild fever; serious side effects are
  possible but extremely rare; after an unexpected reaction, consult a
  health-care worker — WHO vaccine-safety Q&A. The Arabic text in the app
  follows WHO's own Arabic page.

**Arabic:** the IMCI booklet was not available in Arabic in the session;
those strings are our translation of the facts above. The vaccine-safety
wording follows WHO's Arabic page.

**Licence:** the IMCI chart booklet is © World Health Organization 2014,
"all rights reserved", with reproduction or translation by permission; the
app does not reproduce the booklet, it states a handful of its facts in
its own words, with attribution, which the screen shows. WHO web pages are
under WHO's website terms (<https://www.who.int/about/policies/terms-of-use>).

> **Decision for the owner:** if you want certainty beyond attribution of
> short facts, WHO Press grants permission for non-commercial use through
> <https://www.who.int/about/policies/publishing/permissions>. The
> guidance screen can also cite your national MoH material instead, if you
> have it.

## Vaccination schedule

`lib/app/core/service/medical_dates_generator.dart` — unchanged in v1.1.
Modelled on the Palestinian Ministry of Health routine childhood schedule
(WHO EPI); see the comment in that file and the in-app disclaimer.

## Fonts

**Cairo** (regular), `assets/google_fonts/Cairo-Regular.ttf`, SIL Open Font
License 1.1 (`assets/google_fonts/OFL.txt`, also on the app's Licences page).
Used for the UI and embedded in the vaccination-card PDF.

## Packages added in v1.1

| Package | Version | Licence | Why |
| --- | --- | --- | --- |
| [`pdf`](https://pub.dev/packages/pdf) | 3.13.1 | Apache-2.0 | Draws the bilingual vaccination card on the device. Pure Dart; shapes Arabic. |
| [`printing`](https://pub.dev/packages/printing) | 5.15.1 | Apache-2.0 | Hands the PDF to Android's share and print sheets. |
| [`url_launcher`](https://pub.dev/packages/url_launcher) | 6.3.3 | BSD-3-Clause | Opens the phone's dialer for the emergency contact. Published by the Flutter team. |

Both were at 160/160 pub points, null-safe and Dart-3 compatible, last
published September 2026.

## Packages removed in v1.1

`auto_size_text`, `shimmer`, `flutter_screenutil` (no longer used).

## Artwork

The app icon, adaptive icon, splash mark and in-app logo
(`assets/branding/*.svg`) were drawn for this project in v1.1. No
third-party logos, characters or stock artwork.
