import 'package:baby_vax/app/core/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('should create payload with required fields', () {
      final date = DateTime(2026, 1, 10, 9, 0);

      final payload = NotificationPayload(
        id: 'vax_1',
        title: 'Vaccine Reminder',
        body: 'Time for the vaccine',
        scheduledAt: date,
      );

      expect(payload.id, 'vax_1');
      expect(payload.title, 'Vaccine Reminder');
      expect(payload.body, 'Time for the vaccine');
      expect(payload.scheduledAt, date);
    });
  });
}
