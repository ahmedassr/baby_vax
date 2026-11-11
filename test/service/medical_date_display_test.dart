import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Get.addTranslations(AppTranslations().keys));
  tearDown(Get.reset);

  MedicalDatesModel dose({String? code, String name = 'stored name'}) =>
      MedicalDatesModel(
        code: code,
        name: name,
        description: 'stored description',
        date: DateTime(2026, 1, 1),
        state: 'Pending',
      );

  test('every generated vaccine has a name and description in en and ar', () {
    final Map<String, Map<String, String>> keys = AppTranslations().keys;
    for (final entry in MedicalDatesGenerator.schedule) {
      for (final lang in ['en', 'ar']) {
        for (final field in ['name', 'description']) {
          final String key = 'Vaccine_${entry.code}_$field';
          expect(keys[lang]![key], isNotNull, reason: '$lang is missing $key');
          expect(keys[lang]![key], isNotEmpty);
        }
      }
    }
  });

  test('English translations match the generator text', () {
    final Map<String, String> en = AppTranslations().keys['en']!;
    for (final entry in MedicalDatesGenerator.schedule) {
      expect(en['Vaccine_${entry.code}_name'], entry.name);
      expect(en['Vaccine_${entry.code}_description'], entry.description);
    }
  });

  test('a generated dose is shown in the current language, by code', () {
    Get.locale = const Locale('ar');
    final d = dose(code: 'measles_1', name: 'Measles (1st dose)');
    expect(d.displayName, 'الحصبة (الجرعة الأولى)');
    expect(d.displayDescription, contains('الحصبة'));

    Get.locale = const Locale('en');
    expect(d.displayName, 'Measles (1st dose)');
  });

  test('a custom date keeps the user\'s text in every language', () {
    for (final lang in ['en', 'ar']) {
      Get.locale = Locale(lang);
      final d = dose(name: 'Dentist check-up');
      expect(d.displayName, 'Dentist check-up');
      expect(d.displayDescription, 'stored description');
    }
  });

  test('an unknown code falls back to the stored text', () {
    Get.locale = const Locale('ar');
    final d = dose(code: 'from_a_newer_version');
    expect(d.displayName, 'stored name');
    expect(d.displayDescription, 'stored description');
  });
}
