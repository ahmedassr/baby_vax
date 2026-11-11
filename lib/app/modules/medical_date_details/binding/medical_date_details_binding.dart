import 'package:baby_vax/app/core/imports/import_library.dart';

import '../controller/medical_date_details_controller.dart';

class MedicalDateDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MedicalDateDetailsController>(
        () => MedicalDateDetailsController());
  }
}
