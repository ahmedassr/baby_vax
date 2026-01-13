import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../imports/import_manger.dart';

class LocalNotificationProvider implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationProvider(this._plugin);

  @override
  Future<void> initialize() async {
    logger.i('🔔 Initializing Local Notifications');

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);

    logger.i('✅ Local Notifications initialized successfully');
  }

  @override
  Future<void> schedule(NotificationPayload payload) async {
    final tzDate = tz.TZDateTime.from(payload.scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      payload.id.hashCode,
      payload.title,
      payload.body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccine_reminders',
          'Vaccine Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    logger.i('✅ Notification scheduled → → → [${payload.id}]');
  }

  @override
  Future<void> cancel(String id) async {
    logger.w('🗑️ successfully Cancel notification → → → [$id]');
    await _plugin.cancel(id.hashCode);
  }

  @override
  Future<void> cancelAll() async {
    logger.i('🗑️ successfully Cancel all notifications');
    await _plugin.cancelAll();
  }
}
