import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import '../../../core/imports/import_manger.dart';

class MedicalDateDetailsController extends GetxController
    with StateMixin, StateMixinHelper {
  MedicalDatesModel? medicalDate;
  final args = InternalScreenArgs.fromArgs.medicalDate;

  bool get isActive {
    final state = medicalDate?.state;
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
      setError("The current medical dates is missing");
    }
  }

  Future updateState() async {
    setLoading();
    try {
      var data = medicalDate!.copyWith(
        state: MedicalDateStateEnum.completed,
      );
      await AppConstant.fireStoreHelper.updateData(path: [
        "users",
        SessionManager.uId,
        "medical_dates",
        medicalDate?.id ?? ""
      ], date: data.toMap());
      await fetchDate();
    } catch (_) {
      setError("Failed to update the date state");
    }
  }

  Future fetchDate() async {
    setLoading();
    try {
      final date = await AppConstant.fireStoreHelper.fetchData(path: [
        "users",
        SessionManager.uId,
        "medical_dates",
        medicalDate?.id ?? ""
      ], fromMap: (e) => MedicalDatesModel.fromJson(e));
      if (date?.isEmpty ?? true) {
        setEmpty();
      } else {
        medicalDate = date?.first;
        setSuccess();
      }
    } catch (_) {
      setError("Failed to fetch medical date details");
    }
  }
}
