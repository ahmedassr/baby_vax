import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Owns vaccine reminders.
///
/// Reminders are scheduled entirely on the device. There is no server
/// component, so they work with no network at all — which is the point for the
/// users this app targets.
///
/// Two reminders per vaccine, with keys derived from the vaccine's Firestore
/// document id:
///   `<vaccineId>-advance` — the evening before
///   `<vaccineId>-main`    — the morning of
///
/// Those keys hash to stable numeric ids (see `stableNotificationId`), so
/// re-running [syncFromFirestore] replaces reminders in place instead of
/// stacking duplicates.
class NotificationCoordinator extends GetxService {
  NotificationCoordinator({DateTime Function()? clock})
      : _notificationService = Get.find<NotificationService>(),
        _now = clock ?? DateTime.now;

  NotificationService _notificationService;

  /// Injectable clock. Reminder placement is entirely a function of "now", so
  /// tests need to control it to assert the horizon and past-date rules
  /// without depending on the wall clock at the moment the suite runs.
  DateTime Function() _now;

  /// How far ahead reminders are scheduled.
  ///
  /// The vaccination schedule spans 15 years, but Android caps how many alarms
  /// an app may have pending (historically around 500) and silently drops the
  /// rest. Scheduling only the near horizon and topping up on every app start
  /// keeps the app well under that cap, and means a reminder is never more
  /// stale than the user's last app open.
  static const int horizonMonths = 6;

  /// Hard ceiling on pending reminders, as a second line of defence if the
  /// horizon ever lets too many through.
  static const int maxPendingReminders = 200;

  /// For tests.
  void overrideNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// For tests.
  void overrideClock(DateTime Function() clock) {
    _now = clock;
  }

  /// For tests.
  Future<void> cancelAll() => _notificationService.cancelAll();

  /// Asks for the OS notification permission.
  ///
  /// Call this when the user has a reason to say yes — after a schedule exists
  /// — not at cold start. Returns false when denied; callers carry on, since
  /// the schedule itself does not depend on notifications.
  Future<bool> requestPermission() => _notificationService.requestPermission();

  /// Whether reminders will actually be shown. False when the user has
  /// turned this app's notifications off in system settings.
  Future<bool> notificationsEnabled() =>
      _notificationService.areNotificationsEnabled();

  /// Schedules both reminders for one vaccine.
  ///
  /// Silently skips anything already in the past or beyond the horizon.
  Future<void> scheduleVaccine({
    required String vaccineId,
    required String userName,
    required String vaccineName,
    required DateTime date,
  }) async {
    if (vaccineId.isEmpty) {
      logger.w('Refusing to schedule a reminder with an empty vaccine id '
          '($vaccineName): its notification id would collide with other '
          'id-less records.');
      return;
    }

    try {
      final DateTime now = _now();
      final DateTime horizon = _addMonths(now, horizonMonths);

      // Morning of the appointment.
      final DateTime mainAt = DateTime(
        date.year,
        date.month,
        date.day,
        AppConstant.morningReminderHour,
      );

      // Evening before. Derived from the appointment day rather than by
      // subtracting 24h from mainAt, so a DST shift cannot move it onto the
      // wrong calendar day.
      final DateTime dayBefore = date.subtract(const Duration(days: 1));
      final DateTime advanceAt = DateTime(
        dayBefore.year,
        dayBefore.month,
        dayBefore.day,
        AppConstant.eveningReminderHour,
      );

      await _scheduleIfWithinWindow(
        id: '$vaccineId-advance',
        at: advanceAt,
        now: now,
        horizon: horizon,
        title: 'Notification_vaccine_tomorrow_title'.tr,
        body: 'Notification_vaccine_tomorrow_body'.trIsolated(<String, String>{
          'child': userName,
          'vaccine': vaccineName,
        }),
      );

      await _scheduleIfWithinWindow(
        id: '$vaccineId-main',
        at: mainAt,
        now: now,
        horizon: horizon,
        title: 'Notification_vaccine_today_title'.tr,
        body: 'Notification_vaccine_today_body'.trIsolated(<String, String>{
          'child': userName,
          'vaccine': vaccineName,
        }),
      );
    } catch (e, s) {
      // One bad record must not abort a whole sync.
      logger.e('Failed to schedule reminders for [$vaccineName]',
          error: e, stackTrace: s);
    }
  }

  Future<void> _scheduleIfWithinWindow({
    required String id,
    required DateTime at,
    required DateTime now,
    required DateTime horizon,
    required String title,
    required String body,
  }) async {
    if (!at.isAfter(now)) {
      // A past reminder would fire the moment it is scheduled, which reads as
      // a bug. Overdue and same-day vaccines are surfaced in the schedule UI
      // instead.
      logger.i('Skipping [$id]: $at is in the past');
      return;
    }
    if (at.isAfter(horizon)) {
      logger.i('Skipping [$id]: $at is beyond the '
          '$horizonMonths-month horizon (topped up on next app start)');
      return;
    }

    await _notificationService.schedule(NotificationPayload(
      id: id,
      title: title,
      body: body,
      scheduledAt: at,
    ));
  }

  /// Cancels both reminders for one vaccine. Safe to call when none exist.
  Future<void> cancelVaccine(String vaccineId) async {
    try {
      await _notificationService.cancel('$vaccineId-main');
      await _notificationService.cancel('$vaccineId-advance');
      logger.i('Cancelled reminders for [$vaccineId]');
    } catch (e, s) {
      logger.e('Failed to cancel reminders for [$vaccineId]',
          error: e, stackTrace: s);
    }
  }

  /// Rebuilds every reminder from Firestore.
  ///
  /// This is the single entry point for keeping the OS in sync, and is called
  /// on login, on app start, after editing a child or a date, and after a
  /// timezone change. It cancels everything first so reminders for deleted or
  /// rescheduled vaccines cannot survive.
  ///
  /// Reads come from the Firestore cache when offline, so a sync with no
  /// network still reschedules from the last known schedule rather than
  /// wiping reminders.
  Future<void> syncFromFirestore({
    required String userId,
    required String userName,
  }) async {
    if (userId.isEmpty) {
      logger.w('Skipping reminder sync: no signed-in user');
      return;
    }

    try {
      logger.i('Syncing reminders for [$userId]');

      final List<MedicalDatesModel> vaccines =
          await AppConstant.fireStoreHelper1.getCollection(
        path: AppPath.userMedicalDates(userId),
        fromDoc: MedicalDatesModel.fromDocument,
      );

      // Only cancel once the read succeeded. Cancelling first and then failing
      // to read would leave the user with no reminders at all.
      await _notificationService.cancelAll();

      if (vaccines.isEmpty) {
        logger.i('No vaccines for [$userId]; nothing to schedule');
        return;
      }

      // Nearest first, so if the cap is ever hit the most imminent reminders
      // are the ones that survive.
      final List<MedicalDatesModel> upcoming = vaccines
          .where((MedicalDatesModel v) =>
              v.id != null &&
              v.id!.isNotEmpty &&
              v.date.isAfter(_now()) &&
              MedicalDateStateEnum.fromLabel(v.state) ==
                  MedicalDateStateEnum.pending)
          .toList()
        ..sort((MedicalDatesModel a, MedicalDatesModel b) =>
            a.date.compareTo(b.date));

      int scheduled = 0;
      for (final MedicalDatesModel vaccine in upcoming) {
        // Two reminders per vaccine.
        if (scheduled + 2 > maxPendingReminders) {
          logger.w('Reached the $maxPendingReminders reminder cap; '
              'remaining vaccines are scheduled on a later app start');
          break;
        }
        await scheduleVaccine(
          vaccineId: vaccine.id!,
          userName: userName,
          vaccineName: vaccine.displayName,
          date: vaccine.date,
        );
        scheduled += 2;
      }

      logger.i('Reminder sync done for [$userId]');
    } catch (e, s) {
      logger.e('Reminder sync failed for [$userId]', error: e, stackTrace: s);
    }
  }

  /// Re-reads the device timezone and rebuilds reminders against it.
  ///
  /// Reminders are wall-clock events ("09:00 on the day"), so after the user
  /// travels or DST flips, the already-scheduled absolute instants are wrong
  /// and have to be recomputed.
  Future<void> onTimeZoneChanged({
    required String userId,
    required String userName,
  }) async {
    await _notificationService.refreshTimeZone();
    await syncFromFirestore(userId: userId, userName: userName);
  }

  /// Clears every reminder. Used on logout and on account deletion, so a
  /// signed-out device cannot keep notifying about a child's schedule.
  Future<void> cancelAllReminders() async {
    try {
      await _notificationService.cancelAll();
      logger.i('All reminders cancelled');
    } catch (e, s) {
      logger.e('Failed to cancel reminders', error: e, stackTrace: s);
    }
  }

  /// Reminder keys currently pending with the OS. Exposed for diagnostics and
  /// tests.
  Future<List<String>> pendingReminderIds() =>
      _notificationService.pendingIds();

  /// Calendar-correct month addition, clamping the day to the target month's
  /// length (31 Jan + 1 month -> 28/29 Feb).
  static DateTime _addMonths(DateTime from, int months) {
    final int totalMonths = from.month - 1 + months;
    final int year = from.year + (totalMonths ~/ 12);
    final int month = totalMonths % 12 + 1;
    final int lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final int day =
        from.day < lastDayOfTargetMonth ? from.day : lastDayOfTargetMonth;
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }
}
