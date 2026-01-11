
import 'package:baby_vax/app/config/session/session_manager.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/notification/application/notification_coordinator.dart';
import '../../../core/notification/domain/notification_service.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void onLogout() {
    AppConstant.alertService.showAlert(AlertModel.attention(
        message: "Are you sure you want to log out?",
        yesAction: () async{
          AppConstant.getStorage.write(AppConstant.isLoginKey, false);
          SessionManager.uId = "";
          AppConstant.getStorage.clear();
          await Get.find<NotificationService>().cancelAll();
          await FirebaseAuth.instance.signOut();
          Get.toNamed(AppRoutes.login);
        },
        noAction: () => Get.back()));
  }
}
