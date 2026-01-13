import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../../main.dart';

class OneSingleNotificationProvider {

  Future<void> initialize() async {
    OneSignal.initialize(AppConstant.appId);
    await OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener((event) {
      logger.i(
          '🔔 OneSignal clicked: ${event.notification.jsonRepresentation()}');
    });
  }

  Future<void> setUser(String userId) async {
    await OneSignal.login(userId);
    logger.i('✅ OneSignal user linked: $userId');
  }

  Future<void> logout() async {
    await OneSignal.logout();
  }
}
