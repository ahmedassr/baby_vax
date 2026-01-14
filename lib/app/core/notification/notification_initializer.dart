import 'package:baby_vax/app/core/imports/import_manger.dart';

import 'data/onesignal_notification_provider.dart';

class NotificationInitializer {
  static Future<void> init() async {
    final localPlugin = FlutterLocalNotificationsPlugin();
    final localProvider = LocalNotificationProvider(localPlugin);

    await localProvider.initialize();

    Get.put<NotificationService>(localProvider, permanent: true);
    Get.lazyPut<OneSingleNotificationProvider>(
      () => OneSingleNotificationProvider(),
      fenix: true,
    );

    final coordinator = NotificationCoordinator();
    final fcmProvider = FcmNotificationProvider();

    await fcmProvider.initialize(
        onForeground: (_) {},
        onOpened: (_) => Get.toNamed(AppRoutes.medicalDates));

    Get.put<NotificationCoordinator>(coordinator, permanent: true);
    await Get.find<OneSingleNotificationProvider>().initialize();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (SessionManager.uId.isNotEmpty) {
        AppConstant.fireStoreHelper.updateFcmToken(token: token);
      }
    });
  }
}
