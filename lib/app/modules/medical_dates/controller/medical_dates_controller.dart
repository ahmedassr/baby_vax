import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

class MedicalDatesController extends GetxController
    with StateMixin<List<MedicalDatesModel>>, StateMixinHelper {
  List<MedicalDatesModel> dates = <MedicalDatesModel>[].obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchMedicalDates();
  }

  Future<void> fetchMedicalDates() async {
    setLoading();
    await Future.delayed(const Duration(seconds: 2));
    dates.assignAll([
      MedicalDatesModel(date: "18-1-2025", name: "date number 1", state: "Completed"),
      MedicalDatesModel(date: "20-2-2025", name: "date number 2",state: "Missed"),
      MedicalDatesModel(date: "29-9-2025", name: "date number 3",state: "Coming up"),
    ]);
    setSuccess(dates);
  }

  void onMedicalDatePressed(MedicalDatesModel medicalDate) {
    Get.toNamed(AppRoutes.medicalDateDetails);
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: medicalDate));
  }
}
