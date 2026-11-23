import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';

class TipsBinding extends Bindings {
  @override
  void dependencies() {
    // The signed-in shell keeps one TipsController for Home's tip of the
    // day; the list screen reuses it.
    if (!Get.isRegistered<TipsController>()) Get.put(TipsController());
  }
}
