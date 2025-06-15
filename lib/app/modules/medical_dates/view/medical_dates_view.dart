import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/medical_dates/controller/medical_dates_controller.dart';

class MedicalDatesView extends GetView<MedicalDatesController>{
  const MedicalDatesView({super.key});
  @override
  Widget build(BuildContext context) {
    return controller.obx((_) => Center());
  }
}