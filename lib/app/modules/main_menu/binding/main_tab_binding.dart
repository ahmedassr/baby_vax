import 'package:baby_vax/app/core/imports/import_manger.dart';
import '../../health/controller/health_controller.dart';
import '../../home/controller/home_controller.dart';
import '../../notifications/controller/notifications_controller.dart';
import '../../setting/controller/setting_controller.dart';
import '../../tips/controller/tips_controller.dart';

class MainTabsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(MedicalDatesController(), permanent: true);
    Get.put(HealthController(), permanent: true);
    // No Tips tab; Home's tip of the day and the tips list (from Settings)
    // use it.
    Get.put(TipsController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    // The bell's badge needs it on every tab.
    Get.put(NotificationsController(), permanent: true);
  }
}
