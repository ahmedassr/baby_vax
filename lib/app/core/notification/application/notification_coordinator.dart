import 'package:baby_vax/app/core/imports/import_manger.dart';

class NotificationCoordinator extends GetxService {
  NotificationService _notificationService = Get.find<NotificationService>();

  NotificationCoordinator({NotificationService? service})
      : _notificationService = service ?? Get.find<NotificationService>();

  // طريقة للاختبار لتغيير الخدمة
  void overrideNotificationService(NotificationService service) {
    _notificationService = service;
  }

  /// For Test
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
  }

  Future<void> scheduleVaccine({
    required String vaccineId,
    required String userName,
    required String vaccineName,
    required DateTime date,
  }) async {
    try {
      DateTime mainDate = DateTime(date.year, date.month, date.day, 9);
      final difference = mainDate.difference(DateTime.now());
      if (mainDate.isBefore(DateTime.now())) {
        if (difference.inDays == 0) {
          mainDate = DateTime.now().add(const Duration(minutes: 1));
        } else {
          logger.w('⏭️ Skipping past main vaccine [$vaccineName] at $date');
          return;
        }
      }
      final reminder = NotificationPayload(
          id: '$vaccineId-main',
          title: '🧪 موعد تطعيم اليوم',
          body: '👶 $userName\nاليوم موعد تطعيم:\n$vaccineName',
          scheduledAt: mainDate);

      await _notificationService.schedule(reminder);
      logger.i(
          '📅 Scheduled vaccine notifications | Vaccine ID: $vaccineId | Type: Main');
      DateTime dayBefore = mainDate.subtract(const Duration(days: 1));
      if (dayBefore.isBefore(DateTime.now())) {
        logger
            .w('⏭️ Skipping past advance vaccine 🧪 [$vaccineName] at ⏰ $date');
        return;
      }
      final advance = NotificationPayload(
          id: '$vaccineId-advance',
          title: '📅 تذكير مسبق',
          body: '👶 $userName\nغذا موعد تطعيم:\n$vaccineName',
          scheduledAt:
              DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 18));

      await _notificationService.schedule(advance);
      logger.i(
          '📅 Scheduled vaccine notifications | Vaccine ID: $vaccineId | Type: advance');
    } catch (e, s) {
      logger.e(
        '❌ Failed to schedule vaccine [$vaccineName]',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> cancelVaccine(String vaccineId) async {
    try {
      await _notificationService.cancel('$vaccineId-main');
      await _notificationService.cancel('$vaccineId-advance');
      logger.i('🗑️ Vaccine notifications canceled for [$vaccineId]');
    } catch (e, s) {
      logger.e(
        '❌ Failed to cancel vaccine notifications [$vaccineId]',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> rescheduleAllVaccines({
    required String userId,
    required String userName,
  }) async {
    try {
      logger.i('🔄 Rescheduling all vaccine notifications for user [$userId]');
      await _notificationService.cancelAll();

      final vaccines =
          await AppConstant.fireStoreHelper.fetchData<MedicalDatesModel>(
        path: ['users', userId, 'medical_dates'],
        fromDocument: MedicalDatesModel.fromDocument,
      );

      if (vaccines == null || vaccines.isEmpty) {
        logger.w('⚠️ No vaccines found for user [$userId]');
        return;
      }

      for (final vaccine in vaccines) {
        if (vaccine.date.isAfter(DateTime.now())) {
          await scheduleVaccine(
            vaccineId: vaccine.id ?? "",
            userName: userName,
            vaccineName: vaccine.name,
            date: vaccine.date,
          );
        } else {
          logger.w(
              '⏭️ Skipping past vaccine [${vaccine.name}] at ${vaccine.date}');
        }
      }
      logger.i('✅ All future vaccine notifications rescheduled successfully');
    } catch (e, s) {
      logger.e(
        '❌ Failed to reschedule vaccine notifications',
        error: e,
        stackTrace: s,
      );
    }
  }
}
