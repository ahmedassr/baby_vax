import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

class MedicalDatesController extends GetxController
    with StateMixin<List<MedicalDatesModel>>, StateMixinHelper {
  List<MedicalDatesModel> dates = <MedicalDatesModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMedicalDates();
  }

  Future<void> fetchMedicalDates() async {
    setLoading();
    await Future.delayed(const Duration(seconds: 2));
    dates.assignAll([
      MedicalDatesModel(date: "18-8-2025", name: "date number 1"),
      MedicalDatesModel(date: "20-9-2025", name: "date number 2"),
      MedicalDatesModel(date: "29-9-2025", name: "date number 3"),
    ]);
    setSuccess(dates);
  }
}
