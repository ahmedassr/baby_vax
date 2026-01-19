import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> userDetails = Rxn<UserModel>();
  final Rxn<MedicalDatesModel> nextVaccination = Rxn<MedicalDatesModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    getNextVaccination();
  }

  Future<void> getNextVaccination() async {
    final vaccinations =
        await AppConstant.fireStoreHelper.fetchData<MedicalDatesModel>(
      path: ["users", SessionManager.uId, "medical_dates"],
      queryBuilder: (q) => q
          .where('date',
              isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
          .orderBy('date')
          .limit(1),
      fromMap: MedicalDatesModel.fromJson,
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
