import 'package:baby_vax/app/core/imports/import_library.dart';

import '../controller/medical_dates_controller.dart';

class MedicalDatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(() => MedicalDatesController());
  }
}
