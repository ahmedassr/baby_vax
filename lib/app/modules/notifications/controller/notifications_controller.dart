import 'dart:async';

import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/application/notification_feed.dart';
import 'package:baby_vax/app/core/notification/data/notification_settings_opener.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/reminders/controller/reminders_controller.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';

/// The notifications screen and the bell's unread badge.
///
/// Local only: built from the app's own vaccine and custom reminders (see
/// [NotificationFeed]); what has been read is stored on this device, never
/// in Firestore. It is erased with the rest of the parent's data on log out.
class NotificationsController extends GetxController {
  NotificationsController({
    Future<List<ReminderModel>> Function(String uid)? loadReminders,
    List<MedicalDatesModel> Function()? doses,
    Object? Function(String key)? readStore,
    Future<void> Function(String key, Object value)? writeStore,
    Future<bool> Function()? notificationsEnabled,
    NotificationSettingsOpener settingsOpener =
        const NotificationSettingsOpener(),
    DateTime Function()? clock,
    Duration? tick = const Duration(minutes: 1),
  })  : _tick = tick,
        _loadReminders = loadReminders ?? _firestoreReminders,
        _doses = doses ?? _homeDoses,
        _read = readStore ?? _storageRead,
        _write = writeStore ?? _storageWrite,
        _notificationsEnabled =
            notificationsEnabled ?? _coordinatorNotificationsEnabled,
        _settingsOpener = settingsOpener,
        _now = clock ?? DateTime.now;

  final Future<List<ReminderModel>> Function(String uid) _loadReminders;
  final List<MedicalDatesModel> Function() _doses;
  final Object? Function(String key) _read;
  final Future<void> Function(String key, Object value) _write;
  final Future<bool> Function() _notificationsEnabled;
  final NotificationSettingsOpener _settingsOpener;
  final DateTime Function() _now;

  /// How often the list is rebuilt while the app is open, so a reminder
  /// that fires now moves to "delivered" and the badge counts it. Null:
  /// never (tests).
  final Duration? _tick;
  Timer? _timer;

  /// Device storage keys. Not in `StorageKey.devicePreferences`, so they
  /// are cleared on log out with the rest of the parent's data.
  static const String readKey = 'notificationsRead';
  static const String sinceKey = 'notificationsSince';

  /// Oldest first.
  final RxList<FeedItem> items = <FeedItem>[].obs;
  final RxSet<String> readKeys = <String>{}.obs;
  final RxBool notificationsOff = false.obs;
  final RxBool isLoading = false.obs;

  List<ReminderModel> _reminders = <ReminderModel>[];
  AppLifecycleListener? _lifecycle;
  Worker? _dosesWorker;
  DateTime? _since;

  DateTime get now => _now();

  static Future<List<ReminderModel>> _firestoreReminders(String uid) =>
      AppConstant.fireStoreHelper1.getCollection(
          path: AppPath.userReminders(uid),
          fromDoc: ReminderModel.fromDocument);

  static List<MedicalDatesModel> _homeDoses() =>
      Get.isRegistered<HomeController>()
          ? Get.find<HomeController>().doses
          : const <MedicalDatesModel>[];

  static Object? _storageRead(String key) => AppConstant.getStorage.read(key);

  static Future<void> _storageWrite(String key, Object value) =>
      AppConstant.getStorage.write(key, value);

  static Future<bool> _coordinatorNotificationsEnabled() async {
    if (!Get.isRegistered<NotificationCoordinator>()) return true;
    return Get.find<NotificationCoordinator>().notificationsEnabled();
  }

  /// When this device started keeping the list: set the first time, so
  /// reminders from before (which may never have been scheduled here) are
  /// not shown as delivered.
  DateTime get since {
    if (_since != null) return _since!;
    final Object? stored = _read(sinceKey);
    final DateTime? parsed =
        stored is String ? DateTime.tryParse(stored) : null;
    if (parsed != null) return _since = parsed;
    final DateTime n = now;
    unawaited(_write(sinceKey, n.toIso8601String()));
    return _since = n;
  }

  bool isUnread(FeedItem i) => i.deliveredBy(now) && !readKeys.contains(i.key);

  /// Delivered and not yet read: the bell's badge.
  int get unreadCount => items.where(isUnread).length;

  List<FeedItem> section(FeedSection s) {
    final DateTime n = now;
    final List<FeedItem> list =
        items.where((FeedItem i) => i.sectionAt(n) == s).toList();
    // Earlier: the most recent first.
    return s == FeedSection.earlier ? list.reversed.toList() : list;
  }

  @override
  void onInit() {
    super.onInit();
    final Object? stored = _read(readKey);
    if (stored is List) readKeys.addAll(stored.whereType<String>());
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(reload()));
    if (Get.isRegistered<HomeController>()) {
      _dosesWorker =
          ever(Get.find<HomeController>().doses, (_) => unawaited(reload()));
    }
    if (_tick != null) _timer = Timer.periodic(_tick, (_) => _rebuild());
    unawaited(reload());
  }

  @override
  void onClose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    _dosesWorker?.dispose();
    super.onClose();
  }

  /// Re-reads the parent's reminders and the notification permission, and
  /// rebuilds the list. A failed read keeps the last list.
  Future<void> reload() async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    isLoading.value = items.isEmpty;
    try {
      _reminders = await _loadReminders(uid);
    } catch (e, s) {
      logger.w('Loading reminders for notifications failed',
          error: e, stackTrace: s);
    }
    try {
      notificationsOff.value = !(await _notificationsEnabled());
    } catch (_) {
      notificationsOff.value = false;
    }
    _rebuild();
    isLoading.value = false;
  }

  void _rebuild() {
    if (SessionManager.signedInUid == null) return;
    items.assignAll(NotificationFeed.build(
      doses: _doses(),
      reminders: _reminders,
      now: now,
      since: since,
    ));
  }

  Future<void> _save() async {
    // Only keys still on the list are worth keeping.
    final Set<String> live = items.map((FeedItem i) => i.key).toSet();
    readKeys.removeWhere((String k) => !live.contains(k));
    await _write(readKey, readKeys.toList());
  }

  Future<void> markRead(FeedItem i) async {
    if (readKeys.contains(i.key)) return;
    readKeys.add(i.key);
    await _save();
  }

  Future<void> markAllRead() async {
    final DateTime n = now;
    readKeys.addAll(<String>[
      for (final FeedItem i in items)
        if (i.deliveredBy(n)) i.key,
    ]);
    await _save();
  }

  /// Marks [i] read and opens its dose or reminder.
  Future<void> open(FeedItem i) async {
    await markRead(i);
    final MedicalDatesModel? dose = i.dose;
    if (dose != null) {
      AppConstant.argumentService
          .setArgument(InternalScreenArgs(medicalDate: dose));
      await Get.toNamed(AppRoutes.medicalDateDetails);
    } else if (i.reminder?.id != null) {
      await Get.toNamed(AppRoutes.reminders,
          arguments: RemindersController.openEditArgument(i.reminder!.id!));
    }
    unawaited(reload());
  }

  Future<void> openSettings() async {
    if (!await _settingsOpener.open()) {
      AppSnackbar.error("Notification_permission_denied_msg".tr);
    }
  }

  /// Forgets the signed-out parent's list.
  void clearSession() {
    items.clear();
    readKeys.clear();
    _reminders = <ReminderModel>[];
    _since = null;
  }
}
