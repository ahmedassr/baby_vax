import 'package:baby_vax/app/config/session/session_manager.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/notification/application/notification_coordinator.dart';
import '../../../core/notification/domain/notification_service.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;
  var currentLanguage = (Get.locale?.languageCode ?? 'en').obs;
  var locale = Get.locale?.languageCode;

  @override
  void onInit() {
    super.onInit();
    loadThemePreference();
    currentLanguage.value = AppConstant.getStorage.read("language") ?? 'en';
  }

  Future<void> loadThemePreference() async {
    bool savedTheme =
        AppConstant.getStorage.read(StorageKey.isDarkModeKey) ?? false;
    isDarkMode.value = savedTheme;
    Get.changeThemeMode(savedTheme ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    await AppConstant.getStorage.write(StorageKey.isDarkModeKey, value);
  }

  void onLogout() {
    AppConstant.alertService.showAlert(AlertModel.attention(
        message: "SettingsController_logout_alert_msg".tr,
        yesAction: () async {
          await AppConstant.getStorage.write(StorageKey.isLoginKey, false);
          // A signed-out device must not keep notifying about a child's
          // schedule.
          await Get.find<NotificationCoordinator>().cancelAllReminders();
          await FirebaseAuth.instance.signOut();
          SessionManager.uId = "";
          AppConstant.getStorage.clear();
          Get.toNamed(AppRoutes.login);
        },
        noAction: () => Get.back()));
  }

  Future changeLanguage() async {
    String newLang = currentLanguage.value == "ar" ? "en" : "ar";
    Locale newLocale = newLang == "ar" ? const Locale('ar', 'SA') : const Locale('en', 'US');
    Get.updateLocale(newLocale);
    currentLanguage.value = newLang;
    await AppConstant.getStorage.write(StorageKey.languageKey, newLang);
  }
}
