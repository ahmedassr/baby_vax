import 'package:baby_vax/app/core/notification/domain/notification_payload.dart';
import 'package:baby_vax/app/core/notification/domain/notification_service.dart';

/// In-memory [NotificationService] for tests.
///
/// Keeps reminders in a map keyed by payload id, which is what the real
/// providers do via a stable numeric id. Scheduling the same id twice therefore
/// replaces rather than appends — that is the duplicate-reminder property the
/// tests assert on.
class FakeNotificationService implements NotificationService {
  final Map<String, NotificationPayload> store =
      <String, NotificationPayload>{};

  bool cancelAllCalled = false;
  bool initializeCalled = false;
  bool refreshTimeZoneCalled = false;
  int scheduleCallCount = 0;

  /// Controls what [requestPermission] returns, so denial paths are testable.
  bool permissionGranted = true;

  /// Reminders currently scheduled, in insertion order.
  List<NotificationPayload> get scheduled =>
      store.values.toList(growable: false);

  /// Ids currently scheduled, in insertion order.
  List<String> get scheduledIds => store.keys.toList(growable: false);

  @override
  Future<void> schedule(NotificationPayload payload) async {
    scheduleCallCount++;
    store[payload.id] = payload;
  }

  @override
  Future<void> cancel(String id) async {
    store.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
    store.clear();
  }

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  Future<List<String>> pendingIds() async => scheduledIds;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> refreshTimeZone() async {
    refreshTimeZoneCalled = true;
  }
}
