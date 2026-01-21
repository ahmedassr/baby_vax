import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> userDetails = Rxn<UserModel>();
  final Rxn<MedicalDatesModel> nextVaccination = Rxn<MedicalDatesModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }

  Future<void> getNextVaccination() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final vaccinations =
        await AppConstant.fireStoreHelper.fetchData<MedicalDatesModel>(
      path: ["users", SessionManager.uId, "medical_dates"],
      queryBuilder: (q) => q
          .where('state', isEqualTo: MedicalDateStateEnum.pending.label)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('date')
          .limit(1),
      fromDocument: MedicalDatesModel.fromDocument,
    );
    nextVaccination.value = vaccinations?.firstOrNull;
  }

  Future fetchUserData() async {
    var uid = SessionManager.uId;
    if (uid.isEmpty) {
      setError("The user ID is missing.");
      return;
    }
    setLoading();
    try {
      final data = await AppConstant.fireStoreHelper
          .getUser(uid: uid, fromMap: (e) => UserModel.fromJson(e));
      if (data == null) {
        setEmpty();
      } else {
        userDetails.value = data;
        await getNextVaccination();
        setSuccess();
      }
    } catch (_) {
      setError("An unexpected error occurred.");
    }
  }

  void onNextVaccinationPressed() {
    Get.toNamed(AppRoutes.medicalDateDetails);
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: nextVaccination.value));
  }
}
