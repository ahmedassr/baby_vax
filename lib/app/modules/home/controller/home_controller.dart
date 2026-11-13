import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/data/notification_settings_opener.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';
import 'package:baby_vax/app/modules/vaccination_card/vaccination_card_sheet.dart';

/// The home screen: who the schedule is for, the next dose, overall
/// progress and the latest measurements.
class HomeController extends GetxController with StateMixin, StateMixinHelper {
  HomeController({
    Future<bool> Function()? notificationsEnabled,
    NotificationSettingsOpener settingsOpener =
        const NotificationSettingsOpener(),
    Future<UserModel?> Function(String uid)? loadUser,
    Future<List<MedicalDatesModel>> Function(String uid)? loadDoses,
    DateTime Function()? clock,
  })  : _notificationsEnabled =
            notificationsEnabled ?? _coordinatorNotificationsEnabled,
        _settingsOpener = settingsOpener,
        _loadUser = loadUser ?? _firestoreUser,
        _loadDoses = loadDoses ?? _firestoreDoses,
        _now = clock ?? DateTime.now;

  final Future<bool> Function() _notificationsEnabled;
  final NotificationSettingsOpener _settingsOpener;
  final Future<UserModel?> Function(String uid) _loadUser;
  final Future<List<MedicalDatesModel>> Function(String uid) _loadDoses;
  final DateTime Function() _now;

  final Rxn<UserModel> userDetails = Rxn<UserModel>();

  /// The whole schedule, in date order.
  final RxList<MedicalDatesModel> doses = <MedicalDatesModel>[].obs;

  /// The dose the hero card shows. Kept as its own observable for callers
  /// from v1.0 (the details screen refreshes it after a change).
  final Rxn<MedicalDatesModel> nextVaccination = Rxn<MedicalDatesModel>();

  /// True while this app's notifications are off in system settings, so
  /// reminders would not be shown. Drives the banner on the home screen.
  final RxBool notificationsOff = false.obs;

  AppLifecycleListener? _lifecycle;

  /// Counts and the hero dose for today.
  ScheduleSummary get summary => ScheduleSummary(doses, _now());

  static Future<bool> _coordinatorNotificationsEnabled() async {
    if (!Get.isRegistered<NotificationCoordinator>()) return true;
    return Get.find<NotificationCoordinator>().notificationsEnabled();
  }

  static Future<UserModel?> _firestoreUser(String uid) => AppConstant
      .fireStoreHelper1
      .getDocument(path: AppPath.userDoc(uid), fromDoc: UserModel.fromDocument);

  /// The whole schedule (ten documents for a generated one). Read in full
  /// rather than with a `date >= today` query, so overdue doses are seen
  /// and no composite index is needed; offline it comes from the cache.
  static Future<List<MedicalDatesModel>> _firestoreDoses(String uid) async =>
      MedicalDatesController.inScheduleOrder(await AppConstant.fireStoreHelper1
          .getCollection(
              path: AppPath.userMedicalDates(uid),
              fromDoc: MedicalDatesModel.fromDocument));

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

  Future fetchUserData() async {
    // This controller is created at app start, before the splash screen
    // knows whether anyone is signed in. Without a signed-in user there is
    // nothing to read; login and sign-up call this again afterwards.
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    // Only show the skeleton on the first load; a refresh keeps the content
    // on screen.
    if (userDetails.value == null) setLoading();
    try {
      final UserModel? data = await _loadUser(uid);
      if (data == null) {
        setEmpty();
        return;
      }
      userDetails.value = data;
      doses.assignAll(await _loadDoses(uid));
      nextVaccination.value = summary.hero;
      setSuccess();
      await refreshNotificationStatus();
    } catch (e, s) {
      logger.w('Loading the home screen failed', error: e, stackTrace: s);
      setError(friendlyFirebaseError(e));
    }
  }

  /// Forgets the signed-out parent's data.
  void clearSession() {
    userDetails.value = null;
    doses.clear();
    nextVaccination.value = null;
    notificationsOff.value = false;
  }

  void openDose(MedicalDatesModel dose) {
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: dose));
    Get.toNamed(AppRoutes.medicalDateDetails);
  }

  void onNextVaccinationPressed() {
    final MedicalDatesModel? dose = nextVaccination.value;
    if (dose != null) openDose(dose);
  }

  void openEditProfile() {
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(user: userDetails.value));
    Get.toNamed(AppRoutes.editUser);
  }

  /// Opens the growth tracker.
  void openGrowth() => Get.toNamed(AppRoutes.growth);

  /// Opens the vaccination card sheet (share or print the PDF).
  void openVaccinationCard() => VaccinationCardSheet.show();

  /// Switches the bottom navigation to the schedule tab.
  void openSchedule() {
    if (Get.isRegistered<MainMenuController>()) {
      Get.find<MainMenuController>().changeValue(1);
    }
  }
}
