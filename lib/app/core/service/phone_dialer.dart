import 'package:url_launcher/url_launcher.dart';

/// Opens the phone's dialer with a number filled in. The parent presses
/// call themselves, so the app needs no call permission.
class PhoneDialer {
  const PhoneDialer._();

  /// Replaced in tests.
  static Future<bool> Function(String phone) dial = _dial;

  static Future<bool> _dial(String phone) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: phone),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
