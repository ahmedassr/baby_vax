import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, Map<String, String>> keys = AppTranslations().keys;

  // Plural forms English does not have (it only uses one and other).
  final RegExp arabicOnlyPlural = RegExp(r'_(zero|two|few|many)$');

  test('Arabic and English have the same keys, apart from Arabic plurals', () {
    final Set<String> en = keys['en']!.keys.toSet();
    final Set<String> ar = keys['ar']!.keys.toSet();
    expect(en.difference(ar), isEmpty, reason: 'missing in ar');
    expect(
        ar.difference(en).where((k) => !arabicOnlyPlural.hasMatch(k)), isEmpty,
        reason: 'missing in en');
  });

  test('every countdown unit has all six Arabic plural forms', () {
    for (final unit in ['hours', 'days', 'weeks', 'months', 'years']) {
      for (final form in ['zero', 'one', 'two', 'few', 'many', 'other']) {
        final String key = 'VaccinationTimeStatus_${unit}_left_$form';
        expect(keys['ar']![key], isNotNull, reason: 'ar is missing $key');
      }
    }
  });

  test('Arabic text uses Western digits only', () {
    final RegExp easternDigits = RegExp('[٠-٩۰-۹]');
    keys['ar']!.forEach((k, v) {
      expect(easternDigits.hasMatch(v), isFalse, reason: '$k: $v');
    });
  });

  test('Pending is "قيد الانتظار" in Arabic', () {
    expect(keys['ar']!['Pending'], 'قيد الانتظار');
    expect(keys['ar']!['MedicalDateActions_undo'], contains('قيد الانتظار'));
    expect(keys['ar']!['MedicalDateActions_undo'], isNot(contains('قادم')));
  });

  test('every key is used somewhere in lib/ (no dead translations)', () {
    final String source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
            (f) => f.path.endsWith('.dart') && !f.path.contains('/languages/'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    // Keys built at run time from a code or a plural category.
    const List<String> dynamicPrefixes = <String>[
      'Vaccine_',
      'VaccinationTimeStatus_',
      'age_months_',
      'age_years_',
    ];
    final List<String> unused = keys['en']!
        .keys
        .where((k) =>
            !dynamicPrefixes.any(k.startsWith) &&
            !source.contains('"$k"') &&
            !source.contains("'$k'"))
        .toList();
    expect(unused, isEmpty);
  });

  test('no empty translations', () {
    for (final lang in ['en', 'ar']) {
      keys[lang]!.forEach((k, v) {
        expect(v.trim(), isNotEmpty, reason: '$lang $k is empty');
      });
    }
  });

  test('placeholders match between languages', () {
    final RegExp ph = RegExp(r'@\w+');
    keys['en']!.forEach((k, en) {
      final Set<String> a = ph.allMatches(en).map((m) => m[0]!).toSet();
      final Set<String> b =
          ph.allMatches(keys['ar']![k] ?? '').map((m) => m[0]!).toSet();
      expect(b, a, reason: 'placeholders differ for $k');
    });
  });

  group('countdown badge text', () {
    setUp(() => Get.addTranslations(keys));
    tearDown(Get.reset);

    test('English, singular and plural', () {
      Get.locale = const Locale('en');
      expect(VaccinationTimeStatusEnum.daysLeft.withCount(3), '3 days left');
      expect(VaccinationTimeStatusEnum.weeksLeft.withCount(1), '1 week left');
      expect(
          VaccinationTimeStatusEnum.monthsLeft.withCount(5), '5 months left');
      expect(VaccinationTimeStatusEnum.yearsLeft.withCount(2), '2 years left');
      expect(VaccinationTimeStatusEnum.overdue.withCount(null), 'Overdue');
      expect(VaccinationTimeStatusEnum.today.withCount(null), 'Today');
    });

    test('English keeps its wording for every count', () {
      Get.locale = const Locale('en');
      const VaccinationTimeStatusEnum m = VaccinationTimeStatusEnum.monthsLeft;
      expect(m.withCount(0), '0 months left');
      expect(m.withCount(1), '1 month left');
      expect(m.withCount(2), '2 months left');
      expect(m.withCount(3), '3 months left');
      expect(m.withCount(11), '11 months left');
      expect(m.withCount(100), '100 months left');
    });

    test('Arabic months use the CLDR plural forms', () {
      Get.locale = const Locale('ar');
      const VaccinationTimeStatusEnum m = VaccinationTimeStatusEnum.monthsLeft;
      expect(m.withCount(0), 'متبقٍ 0 شهر'); // zero
      expect(m.withCount(1), 'متبقٍ شهر واحد'); // one
      expect(m.withCount(2), 'متبقٍ شهران'); // two
      expect(m.withCount(3), 'متبقٍ 3 أشهر'); // few: 3-10
      expect(m.withCount(10), 'متبقٍ 10 أشهر');
      expect(m.withCount(11), 'متبقٍ 11 شهرًا'); // many: 11-99
      expect(m.withCount(99), 'متبقٍ 99 شهرًا');
      expect(m.withCount(100), 'متبقٍ 100 شهر'); // other
      expect(m.withCount(103), 'متبقٍ 103 أشهر'); // few again
    });

    test('Arabic plural forms for the other units', () {
      Get.locale = const Locale('ar');
      expect(VaccinationTimeStatusEnum.yearsLeft.withCount(2), 'متبقٍ سنتان');
      expect(VaccinationTimeStatusEnum.weeksLeft.withCount(12),
          'متبقٍ 12 أسبوعًا');
      expect(VaccinationTimeStatusEnum.hoursLeft.withCount(5), 'متبقٍ 5 ساعات');
    });

    test('plural categories follow CLDR', () {
      expect(pluralCategory(1, 'en'), 'one');
      expect(pluralCategory(5, 'en'), 'other');
      expect(
          [0, 1, 2, 3, 10, 11, 99, 100, 102, 103, 111]
              .map((n) => pluralCategory(n, 'ar')),
          [
            'zero',
            'one',
            'two',
            'few',
            'few',
            'many',
            'many',
            'other',
            'other',
            'few',
            'many'
          ]);
    });

    test('Arabic, never the raw enum identifier', () {
      Get.locale = const Locale('ar');
      expect(VaccinationTimeStatusEnum.daysLeft.withCount(3), 'متبقٍ 3 أيام');
      expect(VaccinationTimeStatusEnum.overdue.withCount(null), 'متأخر');
      for (final s in VaccinationTimeStatusEnum.values) {
        final String text = s.withCount(2);
        expect(text, isNot(contains(s.name)));
        expect(text, isNot(contains('VaccinationTimeStatus')));
      }
    });
  });
}
