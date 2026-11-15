import 'package:baby_vax/app/core/imports/import_manger.dart';
import '../../home/controller/home_controller.dart';
import '../../growth/controller/growth_controller.dart';
import '../../setting/controller/setting_controller.dart';
import '../../tips/controller/tips_controller.dart';

class MainTabsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(MedicalDatesController(), permanent: true);
    Get.put(GrowthController(), permanent: true);
    // No Tips tab any more; Home's tip of the day and the tips list use it.
    Get.put(TipsController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
  }
}
