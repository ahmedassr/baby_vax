import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../imports/import_manger.dart';
import '../domain/notification_id.dart';

/// Local-notification backend. This is the single source of truth for vaccine
/// reminders: no server is involved, so reminders fire with no network at all.
class LocalNotificationProvider implements NotificationService {
  LocalNotificationProvider(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'vaccine_reminders';
  static const String _channelName = 'Vaccine Reminders';
  static const String _channelDescription =
      'Reminders for your child\'s upcoming vaccination dates.';

  /// Tracks whether [initialize] has run, so a missed init surfaces as a clear
  /// error instead of a confusing platform exception.
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    logger.i('Initializing local notifications');

    tzdata.initializeTimeZones();
    await _applyDeviceTimeZone();

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;

    logger.i('Local notifications initialized (tz: ${tz.local.name})');
  }

  /// Resolves the device's own timezone.
  ///
  /// The previous implementation hardcoded `Asia/Jerusalem`, so every reminder
  /// fired at Palestine's 09:00 regardless of where the user actually was, and
  /// never followed a DST change. Reminders are wall-clock events ("09:00 the
  /// day before"), so they must be anchored to the device zone.
  Future<void> _applyDeviceTimeZone() async {
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e, s) {
      // An unknown or unavailable zone must not break scheduling entirely.
      // UTC keeps the schedule working; the hour may be off for the user until
      // the next successful resolve.
      logger.w('Could not resolve device timezone, falling back to UTC',
          error: e, stackTrace: s);
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Re-reads the device timezone. Call after the system timezone changes so
  /// already-scheduled reminders can be rebuilt against the new zone.
  @override
  Future<void> refreshTimeZone() => _applyDeviceTimeZone();

  @override
  Future<void> schedule(NotificationPayload payload) async {
    _assertInitialized();

    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(payload.scheduledAt, tz.local);

    // Scheduling into the past makes the platform fire immediately, which looks
    // like a spurious reminder. Callers filter past dates, but guard anyway.
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      logger.w('Refusing to schedule [${payload.id}] in the past '
          '($scheduledDate)');
      return;
    }

    await _plugin.zonedSchedule(
      id: stableNotificationId(payload.id),
      scheduledDate: scheduledDate,
      title: payload.title,
      body: payload.body,
      payload: payload.id,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            payload.body,
            contentTitle: payload.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Vaccine reminders are day-level events, so they do not need the
      // SCHEDULE_EXACT_ALARM permission that Play restricts to alarm and
      // calling apps. Inexact delivery lets Android batch the wake-up, which
      // is also easier on the battery.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Custom reminders can repeat: the plugin re-arms the alarm itself
      // at the same time each day / week / month.
      matchDateTimeComponents: switch (payload.repeat) {
        NotificationRepeat.none => null,
        NotificationRepeat.daily => DateTimeComponents.time,
        NotificationRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        NotificationRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
      },
    );

    logger.i('Scheduled [${payload.id}] for $scheduledDate');
  }

  @override
  Future<void> cancel(String id) async {
    _assertInitialized();
    await _plugin.cancel(id: stableNotificationId(id));
    logger.i('Cancelled [$id]');
  }

  @override
  Future<void> cancelAll() async {
    _assertInitialized();
    await _plugin.cancelAll();
    logger.i('Cancelled all notifications');
  }

  @override
  Future<List<String>> pendingIds() async {
    _assertInitialized();
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    // `payload` carries the original string key; the numeric id is a one-way
    // hash, so the payload is the only way back to a readable key.
    return pending
        .map((PendingNotificationRequest r) => r.payload)
        .whereType<String>()
        .toList(growable: false);
  }

  /// Requests POST_NOTIFICATIONS (Android 13+) / the iOS alert permission.
  ///
  /// Returns false when the user denies it. Callers keep working: the schedule
  /// is still written to Firestore and reminders are still scheduled, they just
  /// will not be shown until the user grants the permission in system settings.
  @override
  Future<bool> requestPermission() async {
    _assertInitialized();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } catch (e, s) {
      logger.w('Notification permission request failed',
          error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    _assertInitialized();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IOSFlutterLocalNotificationsPlugin? ios =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        final NotificationsEnabledOptions? options =
            await ios?.checkPermissions();
        return options?.isEnabled ?? false;
      }
      return true;
    } catch (e, s) {
      logger.w('Notification status check failed', error: e, stackTrace: s);
      // Unknown: don't nag the user with a banner we can't back up.
      return true;
    }
  }

  void _assertInitialized() {
    assert(
      _initialized,
      'LocalNotificationProvider.initialize() must be awaited before use.',
    );
  }
}
