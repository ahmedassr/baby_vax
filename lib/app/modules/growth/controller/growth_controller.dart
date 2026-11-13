import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

import '../model/measurement_model.dart';

/// The growth tracker: dated measurements, plotted against the WHO Child
/// Growth Standards for the baby's sex and age.
///
/// After every change the newest value of each metric is copied into the
/// profile's v1.0 fields (weight / height / headSize), so the home tiles,
/// the profile form and older app builds keep showing current numbers.
class GrowthController extends GetxController {
  GrowthController({
    Future<List<MeasurementModel>> Function(String uid)? load,
    Future<WriteOutcome> Function(String uid, MeasurementModel m)? save,
    Future<void> Function(String uid, String id)? delete,
    Future<void> Function(String uid, Map<String, String> fields)?
        updateProfile,
    UserModel? Function()? user,
    DateTime Function()? clock,
  })  : _load = load ?? _firestoreLoad,
        _save = save ?? _firestoreSave,
        _delete = delete ?? _firestoreDelete,
        _updateProfile = updateProfile ?? _firestoreProfile,
        _user = user ?? _homeUser,
        _now = clock ?? DateTime.now;

  final Future<List<MeasurementModel>> Function(String) _load;
  final Future<WriteOutcome> Function(String, MeasurementModel) _save;
  final Future<void> Function(String, String) _delete;
  final Future<void> Function(String, Map<String, String>) _updateProfile;
  final UserModel? Function() _user;
  final DateTime Function() _now;

  /// Newest first.
  final RxList<MeasurementModel> items = <MeasurementModel>[].obs;
  final Rx<GrowthMetric> metric = GrowthMetric.weight.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxnString actionError = RxnString();
  final RxBool savedOffline = false.obs;

  DateTime get now => _now();
  UserModel? get user => _user();
  String? get sex => user?.sex;

  DateTime? get birthDate {
    final String b = user?.birthday ?? '';
    return b.isEmpty ? null : DateTime.tryParse(b);
  }

  /// Age in months today, or null without a birth date.
  double? get ageNow =>
      birthDate == null ? null : GrowthReference.ageInMonths(birthDate!, now);

  /// Whether percentiles can be shown: a sex, a birth date, and under 5.
  bool get percentilesAvailable =>
      sex != null &&
      ageNow != null &&
      (items.isEmpty
          ? ageNow! <= GrowthReference.maxMonths
          : _ageAt(items.last.date) <= GrowthReference.maxMonths);

  double _ageAt(DateTime d) =>
      birthDate == null ? 0 : GrowthReference.ageInMonths(birthDate!, d);

  /// Measurements that have a value for the selected metric, oldest first.
  List<MeasurementModel> get series => items.reversed
      .where((MeasurementModel m) => m.valueOf(metric.value) != null)
      .toList();

  /// The newest measurement of the selected metric, if any.
  MeasurementModel? get latest {
    final List<MeasurementModel> s = series;
    return s.isEmpty ? null : s.last;
  }

  /// [latest] on the WHO reference, or null when it cannot be placed.
  GrowthReading? get latestReading {
    final MeasurementModel? m = latest;
    if (m == null || birthDate == null) return null;
    return GrowthReference.reading(
      metric: metric.value,
      sex: sex,
      ageMonths: _ageAt(m.date),
      value: m.valueOf(metric.value)!,
    );
  }

  /// Age in months at [m]'s date.
  double ageAt(MeasurementModel m) => _ageAt(m.date);

  static Future<List<MeasurementModel>> _firestoreLoad(String uid) =>
      AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userMeasurements(uid),
          fromDoc: MeasurementModel.fromDocument);

  static Future<WriteOutcome> _firestoreSave(String uid, MeasurementModel m) {
    final String coll = AppPath.userMeasurements(uid);
    final String id = m.id ?? AppConstant.fireStoreHelper1.newDocumentId(coll);
    return AppConstant.fireStoreHelper1
        .setData(path: '$coll/$id', data: m.toMap(), merge: false);
  }

  static Future<void> _firestoreDelete(String uid, String id) async {
    await AppConstant.fireStoreHelper1
        .removeData(path: '${AppPath.userMeasurements(uid)}/$id');
  }

  static Future<void> _firestoreProfile(
          String uid, Map<String, String> fields) =>
      AppConstant.fireStoreHelper1
          .updateData(path: AppPath.userDoc(uid), data: fields);

  static UserModel? _homeUser() => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>().userDetails.value
      : null;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void setMetric(GrowthMetric m) {
    if (metric.value == m) return;
    metric.value = m;
    AppHaptics.selection();
  }

  Future<void> fetch() async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    isLoading.value = items.isEmpty;
    loadError.value = null;
    try {
      items.assignAll(MeasurementModel.newestFirst(await _load(uid)));
    } catch (e, s) {
      logger.w('Loading measurements failed', error: e, stackTrace: s);
      loadError.value = friendlyFirebaseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds [m], or replaces it when it has an id.
  Future<bool> saveMeasurement(MeasurementModel m) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null || m.isEmpty) return false;
    actionError.value = null;
    try {
      final WriteOutcome outcome = await _save(uid, m);
      await fetch();
      savedOffline.value = outcome == WriteOutcome.pendingSync;
      await _syncProfile(uid);
      AppHaptics.confirm();
      return true;
    } catch (e, s) {
      logger.w('Saving a measurement failed', error: e, stackTrace: s);
      actionError.value = "Growth_save_failed".tr;
      return false;
    }
  }

  Future<void> deleteMeasurement(MeasurementModel m) async {
    final String? uid = SessionManager.signedInUid;
    final String? id = m.id;
    if (uid == null || id == null) return;
    actionError.value = null;
    try {
      await _delete(uid, id);
      items.removeWhere((MeasurementModel x) => x.id == id);
      await _syncProfile(uid);
    } catch (e, s) {
      logger.w('Deleting a measurement failed', error: e, stackTrace: s);
      actionError.value = "Growth_save_failed".tr;
    }
  }

  /// Copies the newest value of each metric into the profile. Metrics that
  /// were never measured here are left as they are (a value typed at
  /// sign-up stays until a measurement replaces it).
  Future<void> _syncProfile(String uid) async {
    final Map<GrowthMetric, String?> latest =
        MeasurementModel.latestForProfile(items);
    const Map<GrowthMetric, String> profileField = <GrowthMetric, String>{
      GrowthMetric.weight: 'weight',
      GrowthMetric.height: 'height',
      GrowthMetric.head: 'headSize',
    };
    final Map<String, String> fields = <String, String>{
      for (final MapEntry<GrowthMetric, String?> e in latest.entries)
        if (e.value != null) profileField[e.key]!: e.value!,
    };
    if (fields.isEmpty) return;
    try {
      await _updateProfile(uid, fields);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchUserData();
      }
    } catch (e, s) {
      // The measurement itself is saved; the profile copy is a convenience.
      logger.w('Copying measurements to the profile failed',
          error: e, stackTrace: s);
    }
  }
}
