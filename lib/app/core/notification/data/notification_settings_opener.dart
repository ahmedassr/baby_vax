import 'package:flutter/services.dart';

/// Opens the OS screen where the user can turn this app's notifications
/// back on. Implemented in MainActivity.kt.
class NotificationSettingsOpener {
  const NotificationSettingsOpener();

  static const MethodChannel channel =
      MethodChannel('com.ahmedalassar.babyvax/settings');

  /// Returns false if no settings screen could be opened.
  Future<bool> open() async {
    try {
      return await channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Platforms without the channel (iOS has no in-app route yet).
      return false;
    }
  }
}
