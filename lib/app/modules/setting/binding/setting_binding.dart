import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(() => SettingsController());
  }
}
