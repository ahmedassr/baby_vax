import 'package:baby_vax/app/core/imports/import_library.dart';

import 'package:baby_vax/app/modules/milestones/controller/milestones_controller.dart';

import '../controller/growth_controller.dart';

class GrowthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GrowthController>(() => GrowthController());
    Get.lazyPut<MilestonesController>(() => MilestonesController());
  }
}
