import 'notification_payload.dart';

/// Backend-agnostic contract for scheduling reminders.
///
/// Reminders are entirely local. Nothing here talks to a server, so the whole
/// reminder feature keeps working offline.
abstract class NotificationService {
  Future<void> initialize();

  /// Schedules (or replaces) one reminder. Implementations derive a stable
  /// numeric id from [NotificationPayload.id], so scheduling the same payload
  /// twice replaces it rather than producing a duplicate.
  Future<void> schedule(NotificationPayload payload);

  Future<void> cancel(String id);

  Future<void> cancelAll();

  /// String keys of reminders currently pending with the OS.
  Future<List<String>> pendingIds();

  /// Asks for the OS notification permission. Returns false when denied.
  Future<bool> requestPermission();

  /// Whether the OS will show this app's notifications right now. The user
  /// can turn them off in system settings at any time, so check this
  /// instead of remembering the answer to [requestPermission].
  Future<bool> areNotificationsEnabled();

  /// Re-reads the device timezone, for use after a system timezone change.
  Future<void> refreshTimeZone();
}
