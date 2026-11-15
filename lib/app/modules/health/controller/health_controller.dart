import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

import '../model/health_entry.dart';

/// The Health tab: the child's log of temperatures, signs, medicines and
/// notes, the days after a vaccine, and WHO's "when to get help".
///
/// Nothing here diagnoses or advises treatment; [careLevelOf] only picks
/// which of WHO's messages (see [HealthGuidance]) an entry calls for.
class HealthController extends GetxController {
  HealthController({
    Future<List<HealthEntry>> Function(String uid)? load,
    Future<(String, WriteOutcome)> Function(String uid, HealthEntry e)? save,
    Future<void> Function(String uid, String id)? delete,
    UserModel? Function()? user,
    Future<void> Function(String uid, Map<String, dynamic> fields)?
        updateProfile,
    List<MedicalDatesModel> Function()? doses,
    DateTime Function()? clock,
  })  : _load = load ?? _firestoreLoad,
        _save = save ?? _firestoreSave,
        _delete = delete ?? _firestoreDelete,
        _user = user ?? _homeUser,
        _updateProfile = updateProfile ?? _firestoreProfile,
        _doses = doses ?? _homeDoses,
        _now = clock ?? DateTime.now;

  final Future<List<HealthEntry>> Function(String) _load;
  final Future<(String, WriteOutcome)> Function(String, HealthEntry) _save;
  final Future<void> Function(String, String) _delete;
  final UserModel? Function() _user;
  final Future<void> Function(String, Map<String, dynamic>) _updateProfile;
  final List<MedicalDatesModel> Function() _doses;
  final DateTime Function() _now;

  /// Newest first.
  final RxList<HealthEntry> items = <HealthEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxnString actionError = RxnString();
  final RxBool savedOffline = false.obs;

  /// How long after a dose the "after vaccination" card stays. A product
  /// choice (the days a parent is most likely to watch for a reaction),
  /// not a medical period.
  static const int afterVaccineDays = 3;

  /// The window the temperature chart covers.
  static const Duration chartWindow = Duration(hours: 72);

  DateTime get now => _now();
  UserModel? get user => _user();

  DateTime? get birthDate {
    final String b = user?.birthday ?? '';
    return b.isEmpty ? null : DateTime.tryParse(b);
  }

  /// IMCI's young infant (up to 2 months) on [on] (today by default).
  bool youngInfantOn([DateTime? on]) =>
      HealthGuidance.isYoungInfant(birthDate, on ?? now);

  static Future<List<HealthEntry>> _firestoreLoad(String uid) =>
      AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userHealthLog(uid), fromDoc: HealthEntry.fromDocument);

  static Future<(String, WriteOutcome)> _firestoreSave(
      String uid, HealthEntry e) async {
    final String coll = AppPath.userHealthLog(uid);
    final String id = e.id ?? AppConstant.fireStoreHelper1.newDocumentId(coll);
    final WriteOutcome outcome = await AppConstant.fireStoreHelper1
        .setData(path: '$coll/$id', data: e.toMap(), merge: false);
    return (id, outcome);
  }

  static Future<void> _firestoreDelete(String uid, String id) async {
    await AppConstant.fireStoreHelper1
        .removeData(path: '${AppPath.userHealthLog(uid)}/$id');
  }

  static Future<void> _firestoreProfile(
          String uid, Map<String, dynamic> fields) =>
      AppConstant.fireStoreHelper1
          .updateData(path: AppPath.userDoc(uid), data: fields);

  static UserModel? _homeUser() => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>().userDetails.value
      : null;

  static List<MedicalDatesModel> _homeDoses() =>
      Get.isRegistered<HomeController>()
          ? Get.find<HomeController>().doses
          : const <MedicalDatesModel>[];

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    isLoading.value = items.isEmpty;
    loadError.value = null;
    try {
      items.assignAll(HealthEntry.newestFirst(await _load(uid)));
    } catch (e, s) {
      logger.w('Loading the health log failed', error: e, stackTrace: s);
      loadError.value = friendlyFirebaseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Adds [e], or replaces it when it has an id. Incomplete entries are
  /// never written.
  Future<bool> saveEntry(HealthEntry e) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null || !e.isComplete) return false;
    actionError.value = null;
    try {
      final (String id, WriteOutcome outcome) = await _save(uid, e);
      items.removeWhere((HealthEntry x) => x.id == id);
      items.assignAll(
          HealthEntry.newestFirst(<HealthEntry>[...items, e.copyWith(id: id)]));
      savedOffline.value = outcome == WriteOutcome.pendingSync;
      AppHaptics.confirm();
      return true;
    } catch (err, s) {
      logger.w('Saving a health entry failed', error: err, stackTrace: s);
      actionError.value = "Health_save_failed".tr;
      return false;
    }
  }

  Future<void> deleteEntry(HealthEntry e) async {
    final String? uid = SessionManager.signedInUid;
    final String? id = e.id;
    if (uid == null || id == null) return;
    actionError.value = null;
    try {
      await _delete(uid, id);
      items.removeWhere((HealthEntry x) => x.id == id);
    } catch (err, s) {
      logger.w('Deleting a health entry failed', error: err, stackTrace: s);
      actionError.value = "Health_save_failed".tr;
    }
  }

  /// Saves the health profile. A blank field is removed from the
  /// document (not left behind as an empty string), and Home's copy of the
  /// profile is updated at once, so the tab and the card show it offline.
  Future<bool> saveProfile(UserModel updated) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return false;
    actionError.value = null;
    final Map<String, Object?> values = <String, Object?>{
      'allergies': updated.allergies,
      'conditions': updated.conditions,
      'bloodType': updated.bloodType,
      'emergencyContact': updated.emergencyContact?.toMap(),
    };
    try {
      await _updateProfile(uid, <String, dynamic>{
        for (final MapEntry<String, Object?> e in values.entries)
          e.key: e.value ?? FieldValue.delete(),
      });
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().userDetails.value = updated;
      }
      profileOverride.value = updated;
      AppHaptics.confirm();
      return true;
    } catch (err, s) {
      logger.w('Saving the health profile failed', error: err, stackTrace: s);
      actionError.value = "Health_save_failed".tr;
      return false;
    }
  }

  /// The profile as last saved here, until Home reloads it.
  final Rxn<UserModel> profileOverride = Rxn<UserModel>();

  /// The profile the tab shows.
  UserModel? get profile => profileOverride.value ?? user;

  /// Forgets the signed-out parent's log (the tab's controller lives as
  /// long as the app).
  void clearSession() {
    items.clear();
    profileOverride.value = null;
    loadError.value = null;
    actionError.value = null;
    savedOffline.value = false;
  }

  // ---- what the screen shows ----------------------------------------------

  /// WHO's message for [e], judged at the child's age when it was logged.
  CareLevel careLevelOf(HealthEntry e) {
    final bool young = youngInfantOn(e.at);
    return switch (e.kind) {
      HealthEntryKind.temperature => HealthGuidance.forTemperature(
          e.tempC!, e.method ?? TemperatureMethod.other,
          youngInfant: young),
      HealthEntryKind.symptoms =>
        HealthGuidance.forSymptoms(e.symptoms, youngInfant: young),
      _ => CareLevel.none,
    };
  }

  /// Temperatures in the last 72 hours, oldest first.
  List<HealthEntry> get recentTemperatures {
    final DateTime from = now.subtract(chartWindow);
    return items.reversed
        .where((HealthEntry e) =>
            e.kind == HealthEntryKind.temperature && e.at.isAfter(from))
        .toList();
  }

  HealthEntry? get latestTemperature => items
      .where((HealthEntry e) => e.kind == HealthEntryKind.temperature)
      .firstOrNull;

  HealthEntry? get lastMedicine => items
      .where((HealthEntry e) => e.kind == HealthEntryKind.medicine)
      .firstOrNull;

  /// The vaccine dose given most recently within [afterVaccineDays], if
  /// any: the "after vaccination" card is about it.
  MedicalDatesModel? get recentDose {
    final DateTime today = DateTime(now.year, now.month, now.day);
    MedicalDatesModel? best;
    DateTime? bestDay;
    for (final MedicalDatesModel d in _doses()) {
      if (MedicalDateStateEnum.fromLabel(d.state) !=
          MedicalDateStateEnum.completed) {
        continue;
      }
      final DateTime g = d.record.givenDate ?? d.date;
      final DateTime day = DateTime(g.year, g.month, g.day);
      final int ago = today.difference(day).inDays;
      if (ago < 0 || ago >= afterVaccineDays) continue;
      if (bestDay == null || day.isAfter(bestDay)) {
        best = d;
        bestDay = day;
      }
    }
    return best;
  }

  /// 1 on the day [dose] was given, 2 the next day, and so on.
  int dayAfter(MedicalDatesModel dose) {
    final DateTime g = dose.record.givenDate ?? dose.date;
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(g.year, g.month, g.day))
            .inDays +
        1;
  }

  /// Entries grouped by calendar day, newest day first.
  List<(DateTime, List<HealthEntry>)> get byDay {
    final List<(DateTime, List<HealthEntry>)> out =
        <(DateTime, List<HealthEntry>)>[];
    for (final HealthEntry e in items) {
      final DateTime d = DateTime(e.at.year, e.at.month, e.at.day);
      if (out.isNotEmpty && out.last.$1 == d) {
        out.last.$2.add(e);
      } else {
        out.add((d, <HealthEntry>[e]));
      }
    }
    return out;
  }
}
