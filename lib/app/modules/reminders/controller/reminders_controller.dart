import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';

import '../model/reminder_model.dart';

/// The parent's own reminders and appointments: stored in Firestore so they
/// follow the account, scheduled on the phone so they work offline.
class RemindersController extends GetxController {
  RemindersController({
    Future<List<ReminderModel>> Function(String uid)? load,
    Future<(String, WriteOutcome)> Function(String uid, ReminderModel r)? save,
    Future<void> Function(String uid, String id)? delete,
    Future<bool> Function(ReminderModel r)? schedule,
    Future<void> Function(String id)? cancel,
    DateTime Function()? clock,
  })  : _load = load ?? _firestoreLoad,
        _save = save ?? _firestoreSave,
        _delete = delete ?? _firestoreDelete,
        _schedule = schedule ?? _coordinatorSchedule,
        _cancel = cancel ?? _coordinatorCancel,
        _now = clock ?? DateTime.now;

  final Future<List<ReminderModel>> Function(String) _load;
  final Future<(String, WriteOutcome)> Function(String, ReminderModel) _save;
  final Future<void> Function(String, String) _delete;
  final Future<bool> Function(ReminderModel) _schedule;
  final Future<void> Function(String) _cancel;
  final DateTime Function() _now;

  final RxList<ReminderModel> items = <ReminderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxnString actionError = RxnString();
  final RxBool savedOffline = false.obs;

  DateTime get now => _now();

  /// Upcoming first (by next occurrence), then past one-offs, newest first.
  List<ReminderModel> get sorted {
    final DateTime n = now;
    final List<ReminderModel> upcoming = items
        .where((r) => r.nextAfter(n) != null)
        .toList()
      ..sort((a, b) => a.nextAfter(n)!.compareTo(b.nextAfter(n)!));
    final List<ReminderModel> past = items
        .where((r) => r.nextAfter(n) == null)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return <ReminderModel>[...upcoming, ...past];
  }

  static Future<List<ReminderModel>> _firestoreLoad(String uid) =>
      AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userReminders(uid),
          fromDoc: ReminderModel.fromDocument);

  static Future<(String, WriteOutcome)> _firestoreSave(
      String uid, ReminderModel r) async {
    final String coll = AppPath.userReminders(uid);
    final String id = r.id ?? AppConstant.fireStoreHelper1.newDocumentId(coll);
    final WriteOutcome o = await AppConstant.fireStoreHelper1
        .setData(path: '$coll/$id', data: r.toMap(), merge: false);
    return (id, o);
  }

  static Future<void> _firestoreDelete(String uid, String id) async {
    await AppConstant.fireStoreHelper1
        .removeData(path: '${AppPath.userReminders(uid)}/$id');
  }

  static Future<bool> _coordinatorSchedule(ReminderModel r) =>
      Get.find<NotificationCoordinator>().scheduleCustom(r);

  static Future<void> _coordinatorCancel(String id) =>
      Get.find<NotificationCoordinator>().cancelCustom(id);

  /// Route argument that opens the add sheet as soon as the screen shows
  /// (used by the schedule tab's "Add reminder" button).
  static const String openAddArgument = 'add';

  /// Set by the view: opens the add sheet.
  Future<void> Function()? onOpenAdd;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  @override
  void onReady() {
    super.onReady();
    if (Get.arguments == openAddArgument) onOpenAdd?.call();
  }

  Future<void> fetch() async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    isLoading.value = items.isEmpty;
    loadError.value = null;
    try {
      items.assignAll(await _load(uid));
    } catch (e, s) {
      logger.w('Loading reminders failed', error: e, stackTrace: s);
      loadError.value = friendlyFirebaseError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Saves [r] (new when it has no id) and brings its notification in line:
  /// cancelled first, then scheduled again if enabled.
  Future<bool> saveReminder(ReminderModel r) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null || r.title.trim().isEmpty) return false;
    actionError.value = null;
    try {
      final (String id, WriteOutcome outcome) = await _save(uid, r);
      final ReminderModel saved = r.copyWith(id: id);
      items.removeWhere((x) => x.id == id);
      items.add(saved);
      await _cancel(id);
      if (saved.enabled) await _schedule(saved);
      savedOffline.value = outcome == WriteOutcome.pendingSync;
      AppHaptics.confirm();
      return true;
    } catch (e, s) {
      logger.w('Saving a reminder failed', error: e, stackTrace: s);
      actionError.value = "Reminders_save_failed".tr;
      return false;
    }
  }

  Future<void> setEnabled(ReminderModel r, bool enabled) =>
      saveReminder(r.copyWith(enabled: enabled));

  /// Deletes [r] and cancels its notification.
  Future<void> deleteReminder(ReminderModel r) async {
    final String? uid = SessionManager.signedInUid;
    final String? id = r.id;
    if (uid == null || id == null) return;
    actionError.value = null;
    try {
      await _cancel(id);
      await _delete(uid, id);
      items.removeWhere((x) => x.id == id);
    } catch (e, s) {
      logger.w('Deleting a reminder failed', error: e, stackTrace: s);
      actionError.value = "Reminders_save_failed".tr;
    }
  }
}
