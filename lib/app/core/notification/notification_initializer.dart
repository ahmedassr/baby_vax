import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Wires up the local-notification stack.
///
/// There is deliberately no push/FCM path here. Vaccine reminders are
/// scheduled on-device and need no server; see
/// docs/future/cloud-function-reminders.js for why the server path was parked.
class NotificationInitializer {
  static Future<void> init() async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();
    final LocalNotificationProvider provider =
        LocalNotificationProvider(plugin);

    await provider.initialize();

    Get.put<NotificationService>(provider, permanent: true);
    Get.put<NotificationCoordinator>(NotificationCoordinator(),
        permanent: true);
  }
}
