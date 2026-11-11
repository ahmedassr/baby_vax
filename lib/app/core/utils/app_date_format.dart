import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The one place dates are turned into text.
///
/// Every date in the app is a calendar day (a vaccination is due on a day, not
/// at an instant), so there is never a time part. Formatting goes through
/// intl's [DateFormat] for the current app locale, so Arabic gets Arabic month
/// names instead of `2027-01-15 00:00:00.000`.
///
/// Digits are always Western (0-9), in every language, so a date reads the
/// same way as the measurements and descriptions next to it.
class AppDateFormat {
  const AppDateFormat._();

  /// Languages whose intl data would otherwise use native digits.
  static const List<String> _nativeDigitLocales = <String>['ar'];

  /// The app's current language code. Falls back to English.
  static String get currentLocale => Get.locale?.languageCode ?? 'en';

  /// Makes every [DateFormat] created from now on use Western digits,
  /// including the ones Flutter's Material localizations build for the date
  /// picker. Call once, before `runApp`.
  static void useWesternDigits() {
    for (final String locale in _nativeDigitLocales) {
      DateFormat.useNativeDigitsByDefaultFor(locale, false);
    }
  }

  /// Medium date, e.g. "Jan 15, 2027" / "15 يناير 2027".
  static String date(DateTime value, {String? locale}) =>
      (DateFormat.yMMMd(locale ?? currentLocale)..useNativeDigits = false)
          .format(value);
}
