import 'package:baby_vax/app/core/imports/import_manger.dart';
import '../../main/controller/main_controller.dart';
import '../../setting/controller/setting_controller.dart';
import '../../tips/controller/tips_controller.dart';

class MainTabsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MainController(), permanent: true);
    Get.put(MedicalDatesController(), permanent: true);
    Get.put(TipsController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
  }
}
