import 'package:baby_vax/app/core/imports/import_library.dart';

import '../controller/growth_controller.dart';

class GrowthBinding extends Bindings {
  @override
  void dependencies() {
    // The Growth tab keeps one GrowthController; reuse it.
    if (!Get.isRegistered<GrowthController>()) {
      Get.lazyPut<GrowthController>(() => GrowthController());
    }
  }
}
