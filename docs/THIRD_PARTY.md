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

Both were at 160/160 pub points, null-safe and Dart-3 compatible, last
published September 2026.

## Packages removed in v1.1

`auto_size_text`, `shimmer`, `flutter_screenutil` (no longer used).

## Artwork

The app icon, adaptive icon, splash mark and in-app logo
(`assets/branding/*.svg`) were drawn for this project in v1.1. No
third-party logos, characters or stock artwork.
