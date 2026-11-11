import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Arabic-Indic (U+0660..) and extended Arabic-Indic (U+06F0..) digits.
final RegExp easternDigits = RegExp('[٠-٩۰-۹]');

void main() {
  late MaterialLocalizations ar;

  setUpAll(() async {
    // As in main(): before the Material localizations build their formats.
    AppDateFormat.useWesternDigits();
    // Loads Flutter's own Arabic date data, which uses Arabic-Indic digits;
    // this is what put "١٥ يناير ٢٠٢٧" on the device.
    ar = await GlobalMaterialLocalizations.delegate.load(const Locale('ar'));
  });

  final DateTime day = DateTime(2027, 1, 15);

  test('the Arabic date picker shows Western digits', () {
    final MaterialLocalizations l = ar;
    for (final String s in [
      l.formatMediumDate(day),
      l.formatFullDate(day),
      l.formatMonthYear(day),
      l.formatYear(day),
      l.formatCompactDate(day),
    ]) {
      expect(easternDigits.hasMatch(s), isFalse, reason: s);
    }
    expect(l.formatYear(day), '2027');
  });

  test('AppDateFormat shows Arabic dates with Western digits', () {
    final String s = AppDateFormat.date(day, locale: 'ar');
    expect(s, contains('يناير'));
    expect(s, contains('15'));
    expect(s, contains('2027'));
    expect(easternDigits.hasMatch(s), isFalse, reason: s);
  });

  test('AppDateFormat keeps Western digits even if the default changes', () {
    DateFormat.useNativeDigitsByDefaultFor('ar', true);
    addTearDown(() => DateFormat.useNativeDigitsByDefaultFor('ar', false));
    // Prove the default really is native digits now...
    expect(easternDigits.hasMatch(DateFormat.yMMMd('ar').format(day)), isTrue);
    // ...and that AppDateFormat does not follow it.
    expect(
        easternDigits.hasMatch(AppDateFormat.date(day, locale: 'ar')), isFalse);
  });
}
