import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, Map<String, String>> keys = AppTranslations().keys;

  test('Arabic and English have exactly the same keys', () {
    final Set<String> en = keys['en']!.keys.toSet();
    final Set<String> ar = keys['ar']!.keys.toSet();
    expect(en.difference(ar), isEmpty, reason: 'missing in ar');
    expect(ar.difference(en), isEmpty, reason: 'missing in en');
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

    test('Arabic, never the raw enum identifier', () {
      Get.locale = const Locale('ar');
      expect(VaccinationTimeStatusEnum.daysLeft.withCount(3),
          'الأيام المتبقية: 3');
      expect(VaccinationTimeStatusEnum.overdue.withCount(null), 'متأخر');
      for (final s in VaccinationTimeStatusEnum.values) {
        final String text = s.withCount(2);
        expect(text, isNot(contains(s.name)));
        expect(text, isNot(contains('VaccinationTimeStatus')));
      }
    });
  });
}
