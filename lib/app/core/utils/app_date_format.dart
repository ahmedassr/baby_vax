import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The one place dates are turned into text.
///
/// Every date in the app is a calendar day (a vaccination is due on a day, not
/// at an instant), so there is never a time part. Formatting goes through
/// intl's [DateFormat] for the current app locale, so Arabic gets Arabic month
/// names and digits instead of `2027-01-15 00:00:00.000`.
class AppDateFormat {
  const AppDateFormat._();

  /// The app's current language code. Falls back to English.
  static String get currentLocale => Get.locale?.languageCode ?? 'en';

  /// Medium date, e.g. "Jan 15, 2027" / "١٥ يناير ٢٠٢٧".
  static String date(DateTime value, {String? locale}) =>
      DateFormat.yMMMd(locale ?? currentLocale).format(value);
}
