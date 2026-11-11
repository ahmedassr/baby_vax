import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/data/notification_settings_opener.dart';

class HomeController extends GetxController with StateMixin, StateMixinHelper {
  HomeController({
    Future<bool> Function()? notificationsEnabled,
    NotificationSettingsOpener settingsOpener =
        const NotificationSettingsOpener(),
  })  : _notificationsEnabled =
            notificationsEnabled ?? _coordinatorNotificationsEnabled,
        _settingsOpener = settingsOpener;

  final Future<bool> Function() _notificationsEnabled;
  final NotificationSettingsOpener _settingsOpener;

  final Rxn<UserModel> userDetails = Rxn<UserModel>();
  final Rxn<MedicalDatesModel> nextVaccination = Rxn<MedicalDatesModel>();

  /// True while this app's notifications are off in system settings, so
  /// reminders would not be shown. Drives the banner on the home screen.
  final RxBool notificationsOff = false.obs;

  AppLifecycleListener? _lifecycle;

  static Future<bool> _coordinatorNotificationsEnabled() async {
    if (!Get.isRegistered<NotificationCoordinator>()) return true;
    return Get.find<NotificationCoordinator>().notificationsEnabled();
  }

  @override
  void onInit() {
    super.onInit();
    // Re-check when the user comes back, typically from the settings
    // screen the banner opened.
    _lifecycle = AppLifecycleListener(onResume: refreshNotificationStatus);
    fetchUserData();
  }

  @override
  void onClose() {
    _lifecycle?.dispose();
    super.onClose();
  }

  Future<void> refreshNotificationStatus() async {
    if (!SessionManager.isSignedIn) {
      notificationsOff.value = false;
      return;
    }
    notificationsOff.value = !(await _notificationsEnabled());
  }

  Future<void> openNotificationSettings() async {
    final bool opened = await _settingsOpener.open();
    if (!opened) {
      AppConstant.alertService
          .showError(message: "Notification_permission_denied_msg".tr);
    }
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
        await refreshNotificationStatus();
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
