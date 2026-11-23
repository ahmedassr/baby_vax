import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

/// The full schedule, grouped by age, with a status filter.
class MedicalDatesController extends GetxController
    with StateMixin<List<MedicalDatesModel>>, StateMixinHelper {
  MedicalDatesController({
    Future<List<MedicalDatesModel>> Function(String uid)? loadDoses,
    DateTime? Function()? birthday,
    DateTime Function()? clock,
  })  : _loadDoses = loadDoses ?? _firestoreDoses,
        _birthday = birthday ?? _profileBirthday,
        _now = clock ?? DateTime.now;

  final Future<List<MedicalDatesModel>> Function(String uid) _loadDoses;
  final DateTime? Function() _birthday;
  final DateTime Function() _now;

  /// Every dose, in schedule order. The filter is applied on top of this.
  final RxList<MedicalDatesModel> doses = <MedicalDatesModel>[].obs;

  /// The status shown, or null for all.
  final Rxn<DoseDisplayStatus> filter = Rxn<DoseDisplayStatus>();

  ScheduleSummary get summary => ScheduleSummary(doses, _now());

  /// The filtered doses, grouped by the age they are due at.
  List<AgeGroup> get groups =>
      groupByAge(summary.filtered(filter.value), birthday: _birthday());

  DateTime get now => _now();

  static Future<List<MedicalDatesModel>> _firestoreDoses(String uid) =>
      AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userMedicalDates(uid),
          fromDoc: MedicalDatesModel.fromDocument);

  /// The birth date from the profile the home screen loaded, used to place
  /// doses that have no schedule code.
  static DateTime? _profileBirthday() {
    if (!Get.isRegistered<HomeController>()) return null;
    final String? b = Get.find<HomeController>().userDetails.value?.birthday;
    return b == null || b.isEmpty ? null : DateTime.tryParse(b);
  }

  @override
  void onInit() {
    super.onInit();
    fetchMedicalDates();
  }

  void setFilter(DoseDisplayStatus? value) {
    if (filter.value == value) return;
    filter.value = value;
    AppHaptics.selection();
  }

  void onMedicalDatePressed(MedicalDatesModel medicalDate) {
    AppConstant.argumentService
        .setArgument(InternalScreenArgs(medicalDate: medicalDate));
    Get.toNamed(AppRoutes.medicalDateDetails);
  }

  /// Oldest date first, the order a parent works through the schedule.
  ///
  /// Sorted here rather than with `orderBy('date')`: Firestore returns
  /// documents in id order, and the ids are random, so without this the
  /// list came back shuffled. Ties keep a stable order by id.
  static List<MedicalDatesModel> inScheduleOrder(
          Iterable<MedicalDatesModel> doses) =>
      doses.toList()
        ..sort((MedicalDatesModel a, MedicalDatesModel b) {
          final int byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : (a.id ?? '').compareTo(b.id ?? '');
        });

  Future fetchMedicalDates() async {
    // Created at app start; nothing to read until someone signs in. The
    // schedule tab fetches again when opened.
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    // Keep the list on screen during a refresh; skeleton only the first time.
    if (doses.isEmpty) setLoading();
    try {
      final List<MedicalDatesModel> medicalDates =
          inScheduleOrder(await _loadDoses(uid));
      // Read-only. The app never changes a dose's state on its own: a past
      // Pending dose stays Pending and is shown as overdue. Only the user
      // marks doses Completed or Skipped (see VaccineStateService).
      doses.assignAll(medicalDates);
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
