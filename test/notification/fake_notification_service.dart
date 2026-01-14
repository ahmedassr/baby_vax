import 'package:baby_vax/app/core/notification/domain/notification_payload.dart';
import 'package:baby_vax/app/core/notification/domain/notification_service.dart';

class FakeNotificationService implements NotificationService {
  List<NotificationPayload> scheduled = [];
  bool cancelAllCalled = false;

  @override
  Future<void> schedule(NotificationPayload payload) async {
    scheduled.add(payload);
  }

  @override
  Future<void> cancel(String id) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }

  @override
  Future<void> initialize() async {}
}
