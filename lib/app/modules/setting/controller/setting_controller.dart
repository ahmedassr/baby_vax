import 'package:baby_vax/app/config/session/session_manager.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/notification/application/notification_coordinator.dart';
import '../../../core/notification/data/onesignal_notification_provider.dart';
import '../../../core/notification/domain/notification_service.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadThemePreference();
  }

  Future<void> loadThemePreference() async {
    bool savedTheme =
        AppConstant.getStorage.read(AppConstant.isDarkModeKey) ?? false;
    isDarkMode.value = savedTheme;
    Get.changeThemeMode(savedTheme ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    await AppConstant.getStorage.write(AppConstant.isDarkModeKey, value);
  }

  void onLogout() {
    AppConstant.alertService.showAlert(AlertModel.attention(
        message: "SettingsController_logout_alert_msg".tr,
        yesAction: () async {
          await AppConstant.getStorage.write(AppConstant.isLoginKey, false);
          await Get.find<NotificationService>().cancelAll();
          await FirebaseAuth.instance.signOut();
          await Get.find<OneSingleNotificationProvider>().logout();
          SessionManager.uId = "";
          AppConstant.getStorage.clear();
          Get.toNamed(AppRoutes.login);
        },
        noAction: () => Get.back()));
  }
}
