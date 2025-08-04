
import 'package:baby_vax/app/config/session/session_manager.dart';

import '../../../core/imports/import_manger.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void onLogout() {
    AppConstant.alertService.showAlert(AlertModel.attention(
        message: "Are you sure you want to log out?",
        yesAction: () {
          AppConstant.getStorage.write(AppConstant.isLoginKey, false);
          SessionManager.uId = "";
          AppConstant.getStorage.clear();
          Get.toNamed(AppRoutes.login);
        },
        noAction: () => Get.back()));
  }
}
