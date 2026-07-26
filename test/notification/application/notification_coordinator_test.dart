import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_notification_service.dart';

void main() {
  group('NotificationCoordinator', () {
    late FakeNotificationService fakeService;
    late NotificationCoordinator coordinator;

    setUp(() {
      fakeService = FakeNotificationService();
      Get.put<NotificationService>(fakeService); // 👈 هنا نضع الخدمة الوهمية
      coordinator = NotificationCoordinator();

      // override internal service with fake
      coordinator.overrideNotificationService(fakeService);
    });

    test('should schedule vaccine correctly', () async {
      final date = DateTime.now().add(const Duration(days: 3));

      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: date,
      );

      // تحقق من أن آخر إشعار تم جدولته
      expect(fakeService.scheduled.length, 2);
      expect(fakeService.scheduled[0].id, 'vax_1-main');
      expect(fakeService.scheduled[1].id, 'vax_1-advance');
    });

    test('should cancel all notifications', () async {
      await coordinator.cancelAll();
      expect(fakeService.cancelAllCalled, true);
    });
  });
}
