import 'package:baby_vax/app/config/constant/app_path.dart';

import '../../../core/imports/import_manger.dart';

class MedicalDateDetailsController extends GetxController
    with StateMixin, StateMixinHelper {
  MedicalDatesModel? medicalDate;
  final args = InternalScreenArgs.fromArgs.medicalDate;

  bool get isActive {
    final state = MedicalDateStateEnum.fromLabel(medicalDate?.state);
    final date = medicalDate?.date;

    if (state != MedicalDateStateEnum.pending || date == null) {
      return false;
    }
    return date.isBefore(DateTime.now());
  }

  @override
  void onInit() {
    super.onInit();
    initializeMedicalDateArgument();
    setSuccess();
  }

  void initializeMedicalDateArgument() {
    if (args != null) {
      medicalDate = args;
    } else {
      setError("MedicalDateDetailsController_missing_medical_dates_msg".tr);
    }
  }

  Future fetchDate() async {
    setLoading();
    try {
      // final date = await AppConstant.fireStoreHelper.fetchData(path: [
      //   "users",
      //   SessionManager.uId,
      //   "medical_dates",
      //   medicalDate?.id ?? ""
      // ], fromDocument: MedicalDatesModel.fromDocument);
      final data = await AppConstant.fireStoreHelper1.getDocument(
          path:
              "${AppPath.userMedicalDates(SessionManager.uId)}/${medicalDate?.id}",
          fromDoc: MedicalDatesModel.fromDocument);
      if (data == null) {
        setEmpty();
      } else {
        medicalDate = data;
        setSuccess();
      }
    } catch (_) {
      setError("MedicalDateDetailsController_fetch_failed_msg".tr);
    }
  }

  Future updateState() async {
    setLoading();
    try {
      var data = medicalDate!.copyWith(
        state: MedicalDateStateEnum.completed.label,
      );
      // await AppConstant.fireStoreHelper.updateData(path: [
      //   "users",
      //   SessionManager.uId,
      //   "medical_dates",
      //   medicalDate?.id ?? ""
      // ], date: data.toMap());
      await AppConstant.fireStoreHelper1.updateData(
          path:
              "${AppPath.userMedicalDates(SessionManager.uId)}/${medicalDate?.id}",
          data: data.toMap());

      await fetchDate();
    } catch (_) {
      setError("MedicalDateDetailsController_state_update_failed_msg".tr);
    }
  }
}
