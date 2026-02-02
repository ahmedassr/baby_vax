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
    setLoading();
    try {
      // final medicalDates = await AppConstant.fireStoreHelper.fetchData(
      //     path: ["users", SessionManager.uId, "medical_dates"],
      //     queryBuilder: (q) => q.orderBy('date'),
      //     fromDocument: MedicalDatesModel.fromDocument);
      final medicalDates = await AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userMedicalDates(SessionManager.uId),
          fromDoc: MedicalDatesModel.fromDocument);
      if (medicalDates.isEmpty) {
        setEmpty();
      } else {
        setSuccess(medicalDates);
        await updateMedicalDateStatus(medicalDates);
      }
    } catch (_) {
      setError("MedicalDatesController_fetch_failed".tr);
    }
  }

  Future updateMedicalDateStatus(List<MedicalDatesModel> medicalDates) async {
    final futures = medicalDates
        .where((m) =>
            m.date.isBefore(DateTime.now()) &&
            m.state == MedicalDateStateEnum.pending.label)
        .map((m) {
      final docId = m.id;
      if (docId == null) return null;
      // return AppConstant.fireStoreHelper.updateData(
      //     path: ["users", SessionManager.uId, "medical_dates", docId],
      //     date: {'state': MedicalDateStateEnum.skipped.label});

      return AppConstant.fireStoreHelper1.updateData(
          path: "${AppPath.userMedicalDates(SessionManager.uId)}/$docId",
          data: {'state': MedicalDateStateEnum.skipped.label});
    }).whereType<Future>();
    await Future.wait(futures);
  }
}
