import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());
  tearDown(Get.reset);

  final DateTime late = DateTime(2027, 1, 15, 23, 59, 59);

  test('English: a medium date with no time part', () {
    expect(AppDateFormat.date(late, locale: 'en'), 'Jan 15, 2027');
  });

  test('Arabic: Arabic month name, no time part', () {
    final String ar = AppDateFormat.date(late, locale: 'ar');
    expect(ar, contains('يناير'));
    expect(ar, isNot(contains('23')));
    expect(ar, isNot(contains(':')));
  });

  test('follows the app locale', () {
    Get.locale = const Locale('ar');
    expect(AppDateFormat.date(late), AppDateFormat.date(late, locale: 'ar'));
    Get.locale = const Locale('en');
    expect(AppDateFormat.date(late), 'Jan 15, 2027');
  });

  test('never prints the raw DateTime form', () {
    for (final lang in ['en', 'ar']) {
      final String s = AppDateFormat.date(DateTime(2027, 1, 15), locale: lang);
      expect(s, isNot(contains('00:00')));
      expect(s, isNot(contains('.000')));
    }
  });

  test('sign-up stores the birthday as an ISO date in any language', () {
    Get.locale = const Locale('ar');
    final c = SignupController();
    c.selectedBirthday.value = DateTime(2025, 3, 4);
    expect(c.birthdayForStorage, '2025-03-04');
    expect(MedicalDatesGenerator.parseBirthDate(c.birthdayForStorage),
        DateTime(2025, 3, 4));
  });
}
