import 'package:baby_vax/app/config/session/session_manager.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

class MedicalDatesController extends GetxController
    with StateMixin<List<MedicalDatesModel>>, StateMixinHelper {
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchMedicalDates();
  }

  void onMedicalDatePressed(MedicalDatesModel medicalDate) {
    Get.toNamed(AppRoutes.medicalDateDetails);
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: medicalDate));
  }

  Future fetchMedicalDates() async {
    setLoading();
    try {
      final medicalDates = await AppConstant.fireStoreHelper.fetchData(
          path: ["users", SessionManager.uId, "medical_dates"],
          fromMap: (e) => MedicalDatesModel.fromJson(e));
      if (medicalDates?.isEmpty ?? true) {
        setEmpty();
      } else {
        setSuccess(medicalDates);
      }
    } catch (_) {
      setError("Failed to fetch medical dates.");
    }
  }
}
