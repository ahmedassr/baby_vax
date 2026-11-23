/// How a scheduled notification repeats. Only custom reminders repeat;
/// vaccine reminders are one-off.
enum NotificationRepeat { none, daily, weekly, monthly }

/// One notification to schedule.
class NotificationPayload {
  /// String key; the platform id is derived from it with
  /// `stableNotificationId`, so the same key always replaces itself.
  final String id;
  final String title;
  final String body;

  /// The (first) time it fires, local wall-clock.
  final DateTime scheduledAt;

  /// Repeats at the same time every day / week / month after [scheduledAt].
  final NotificationRepeat repeat;

  NotificationPayload(
      {required this.id,
      required this.title,
      required this.body,
      required this.scheduledAt,
      this.repeat = NotificationRepeat.none});
}
