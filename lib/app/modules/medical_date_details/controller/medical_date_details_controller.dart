import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import '../../../core/imports/import_manger.dart';

class MedicalDateDetailsController extends GetxController
    with StateMixin, StateMixinHelper {
  MedicalDatesModel? medicalDate;
  final args = InternalScreenArgs.fromArgs.medicalDate;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initializeMedicalDateArgument();
  }

  void initializeMedicalDateArgument() {
    if (args != null) {
      medicalDate = args;
    } else {
      setError("The current medical dates is missing");
    }
  }
}
