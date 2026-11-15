import 'package:get/get.dart';

/// Form validation shared by sign-in, sign-up, password reset and the
/// profile. Each returns a translated message, or null when the value is
/// fine.
class Validators {
  const Validators._();

  /// Deliberately loose: one "@", something either side, a dot in the
  /// domain. Firebase is the real judge; this only catches typos early so
  /// the parent is not sent to the network for "name@gmail".
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Firebase's own minimum. Asking for more locally would reject passwords
  /// v1.0 accounts were created with.
  static const int minPasswordLength = 6;

  static String? email(String value) {
    final String v = value.trim();
    if (v.isEmpty) return "empty_email_error_msg".tr;
    if (!_email.hasMatch(v)) return "error_invalid_email_msg".tr;
    return null;
  }

  /// Sign-in only checks presence: the password was set long ago and the
  /// server decides.
  static String? passwordPresent(String value) =>
      value.isEmpty ? "empty_password_error_msg".tr : null;

  /// A new password must meet Firebase's minimum.
  static String? newPassword(String value) {
    if (value.isEmpty) return "empty_password_error_msg".tr;
    if (value.length < minPasswordLength) {
      return "short_password_error_msg".trParams({'min': '$minPasswordLength'});
    }
    return null;
  }

  static String? requiredText(String value, String emptyMessageKey) =>
      value.trim().isEmpty ? emptyMessageKey.tr : null;

  /// An optional measurement: empty is fine, otherwise a positive number
  /// within [min]..[max]. Accepts a comma as the decimal separator, which
  /// Arabic keyboards produce.
  static String? optionalMeasurement(String value,
      {required double min, required double max}) {
    final String v = value.trim();
    if (v.isEmpty) return null;
    final double? n = parseDecimal(v);
    if (n == null) return "invalid_number_error_msg".tr;
    if (n < min || n > max) {
      return "out_of_range_error_msg"
          .trParams({'min': _fmt(min), 'max': _fmt(max)});
    }
    return null;
  }

  /// Parses "3.4", "3,4" and "٣٫٤" (Arabic-Indic digits and decimal
  /// separator) as 3.4.
  static double? parseDecimal(String value) {
    const String eastern = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer b = StringBuffer();
    for (final int c in value.trim().runes) {
      final String ch = String.fromCharCode(c);
      final int i = eastern.indexOf(ch);
      if (i >= 0) {
        b.write(i);
      } else if (ch == ',' || ch == '٫') {
        b.write('.');
      } else {
        b.write(ch);
      }
    }
    return double.tryParse(b.toString());
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
