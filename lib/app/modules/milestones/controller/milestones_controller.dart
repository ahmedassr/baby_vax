import 'dart:async';

import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

import '../model/milestone_record.dart';

/// The six WHO motor milestones for the baby: what is recorded, and where
/// each one stands for the baby's age today.
class MilestonesController extends GetxController {
  MilestonesController({
    Future<List<MilestoneRecord>> Function(String uid)? load,
    Future<WriteOutcome> Function(String uid, MilestoneRecord r)? save,
    Future<void> Function(String uid, MotorMilestone m)? delete,
    UserModel? Function()? user,
    DateTime Function()? clock,
    Future<bool> Function(String message)? confirmRemove,
  })  : confirmRemove = confirmRemove ?? _askRemove,
        _load = load ?? loadFromFirestore,
        _save = save ?? _firestoreSave,
        _delete = delete ?? _firestoreDelete,
        _user = user ?? _homeUser,
        _now = clock ?? DateTime.now;

  final Future<List<MilestoneRecord>> Function(String) _load;
  final Future<WriteOutcome> Function(String, MilestoneRecord) _save;
  final Future<void> Function(String, MotorMilestone) _delete;
  final UserModel? Function() _user;
  final DateTime Function() _now;

  /// Asks before removing a recorded milestone; true removes it.
  final Future<bool> Function(String message) confirmRemove;

  static Future<bool> _askRemove(String message) async {
    final Completer<bool> yes = Completer<bool>();
    await AppConstant.alertService.showAlert(AlertModel.attention(
      message: message,
      yesAction: () => yes.complete(true),
      noAction: () => yes.complete(false),
    ));
    if (!yes.isCompleted) yes.complete(false);
    return yes.future;
  }

  final RxMap<MotorMilestone, MilestoneRecord> records =
      <MotorMilestone, MilestoneRecord>{}.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxnString actionError = RxnString();
  final RxBool savedOffline = false.obs;

  DateTime get now => _now();
  UserModel? get user => _user();

  String get childName => reminderChildName(user?.name);

  DateTime? get birthDate {
    final String b = user?.birthday ?? '';
    return b.isEmpty ? null : DateTime.tryParse(b);
  }

  /// Age in months today, or null without a birth date.
  double? get ageNow =>
      birthDate == null ? null : GrowthReference.ageInMonths(birthDate!, now);

  /// Whole calendar months today ("10 months" on the 10th when born on a
  /// 10th), for the summary; null without a birth date.
  int? get wholeMonthsNow {
    final DateTime? b = birthDate;
    if (b == null) return null;
    final DateTime n = now;
    final int months =
        (n.year - b.year) * 12 + n.month - b.month - (n.day < b.day ? 1 : 0);
    return months < 0 ? 0 : months;
  }

  /// Age in months on [d], or null without a birth date.
  double? ageOn(DateTime d) =>
      birthDate == null ? null : GrowthReference.ageInMonths(birthDate!, d);

  MilestoneRecord? recordOf(MotorMilestone m) => records[m];

  MilestoneStatus statusOf(MotorMilestone m) => MilestoneStatus.of(
      milestone: m, achievedAt: records[m]?.achievedAt, ageMonths: ageNow);

  int get achievedCount =>
      records.values.where((MilestoneRecord r) => r.achieved).length;

  /// Everything recorded for [uid]; also used by the vaccination card.
  static Future<List<MilestoneRecord>> loadFromFirestore(String uid) async {
    final List<MilestoneRecord?> all = await AppConstant.fireStoreHelper1
        .getCollection<MilestoneRecord?>(
            path: AppPath.userMilestones(uid),
            fromDoc: MilestoneRecord.fromDocument);
    return all.whereType<MilestoneRecord>().toList();
  }

  static Future<WriteOutcome> _firestoreSave(String uid, MilestoneRecord r) =>
      AppConstant.fireStoreHelper1.setData(
          path: '${AppPath.userMilestones(uid)}/${r.milestone.id}',
          data: r.toMap(),
          merge: false);

  static Future<void> _firestoreDelete(String uid, MotorMilestone m) async {
    await AppConstant.fireStoreHelper1
        .removeData(path: '${AppPath.userMilestones(uid)}/${m.id}');
  }

  static UserModel? _homeUser() => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>().userDetails.value
      : null;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    isLoading.value = records.isEmpty;
    loadError.value = null;
    try {
      final List<MilestoneRecord> all = await _load(uid);
      records.assignAll(<MotorMilestone, MilestoneRecord>{
        for (final MilestoneRecord r in all) r.milestone: r,
      });
    } catch (e, s) {
      logger.w('Loading milestones failed', error: e, stackTrace: s);
      loadError.value = friendlyFirebaseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Stores [r] (a date, a note, or both).
  Future<bool> saveRecord(MilestoneRecord r) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null || r.isEmpty) return false;
    actionError.value = null;
    try {
      final WriteOutcome outcome = await _save(uid, r);
      records[r.milestone] = r;
      savedOffline.value = outcome == WriteOutcome.pendingSync;
      if (r.achieved) AppHaptics.confirm();
      return true;
    } catch (e, s) {
      logger.w('Saving a milestone failed', error: e, stackTrace: s);
      actionError.value = "Milestone_save_failed".tr;
      return false;
    }
  }

  /// Keeps [note] for the doctor visit, with the date if there is one.
  Future<bool> saveNote(MotorMilestone m, String note) {
    final MilestoneRecord? r = records[m];
    final String trimmed = note.trim();
    final MilestoneRecord next = MilestoneRecord(
        milestone: m,
        achievedAt: r?.achievedAt,
        note: trimmed.isEmpty ? null : trimmed);
    if (next.isEmpty) return removeRecord(m);
    return saveRecord(next);
  }

  /// Removes everything recorded for [m].
  Future<bool> removeRecord(MotorMilestone m) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return false;
    actionError.value = null;
    try {
      await _delete(uid, m);
      records.remove(m);
      return true;
    } catch (e, s) {
      logger.w('Removing a milestone failed', error: e, stackTrace: s);
      actionError.value = "Milestone_save_failed".tr;
      return false;
    }
  }
}
