import 'notification_payload.dart';

abstract class NotificationService{
  Future<void> initialize();
  Future<void> schedule(NotificationPayload payload);
  Future<void> cancel(String id);
  Future<void> cancelAll();
}