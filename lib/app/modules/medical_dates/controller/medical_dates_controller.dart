import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

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
    // Created at app start; nothing to read until someone signs in. The
    // schedule tab fetches again when opened.
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    setLoading();
    try {
      // final medicalDates = await AppConstant.fireStoreHelper.fetchData(
      //     path: ["users", SessionManager.uId, "medical_dates"],
      //     queryBuilder: (q) => q.orderBy('date'),
      //     fromDocument: MedicalDatesModel.fromDocument);
      final medicalDates = await AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userMedicalDates(uid),
          fromDoc: MedicalDatesModel.fromDocument);
      // Read-only. The app never changes a dose's state on its own: a past
      // Pending dose stays Pending and is shown as overdue. Only the user
      // marks doses Completed or Skipped (see VaccineStateService).
      if (medicalDates.isEmpty) {
        setEmpty();
      } else {
        setSuccess(medicalDates);
      }
    } catch (_) {
      setError("MedicalDatesController_fetch_failed".tr);
    }
  }
}
