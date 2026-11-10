import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

class HomeController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> userDetails = Rxn<UserModel>();
  final Rxn<MedicalDatesModel> nextVaccination = Rxn<MedicalDatesModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> getNextVaccination(String uid) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    // final vaccinations =
    //     await AppConstant.fireStoreHelper.fetchData<MedicalDatesModel>(
    //   path: ["users", SessionManager.uId, "medical_dates"],
    //   queryBuilder: (q) => q
    //       .where('state', isEqualTo: MedicalDateStateEnum.pending.label)
    //       .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
    //       .orderBy('date')
    //       .limit(1),
    //   fromDocument: MedicalDatesModel.fromDocument,
    // );
    final vaccinations = await AppConstant.fireStoreHelper1.getCollection(
      path: AppPath.userMedicalDates(uid),
      fromDoc: MedicalDatesModel.fromDocument,
      queryBuilder: (q) => q
          .where('state', isEqualTo: MedicalDateStateEnum.pending.label)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .orderBy('date')
          .limit(1),
    );
    nextVaccination.value = vaccinations.firstOrNull;
  }

  Future fetchUserData() async {
    // This controller is created at app start, before the splash screen
    // knows whether anyone is signed in. Without a signed-in user there is
    // nothing to read; login and sign-up call this again afterwards.
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    setLoading();
    try {
      // final data = await AppConstant.fireStoreHelper
      //     .getUser(uid: uid, fromDocument: (e) => UserModel.fromDocument(e));
      final data = await AppConstant.fireStoreHelper1.getDocument(
          path: AppPath.userDoc(uid), fromDoc: UserModel.fromDocument);
      if (data == null) {
        setEmpty();
      } else {
        userDetails.value = data;
        await getNextVaccination(uid);
        setSuccess();
      }
    } catch (_) {
      setError("unexpected_error".tr);
    }
  }

  void onNextVaccinationPressed() {
    Get.toNamed(AppRoutes.medicalDateDetails);
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: nextVaccination.value));
  }
}
