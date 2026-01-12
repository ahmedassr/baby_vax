import 'package:baby_vax/app/core/imports/import_manger.dart';

class NotificationCoordinator extends GetxService {
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  Future<void> scheduleVaccine({
    required String vaccineId,
    required String userName,
    required String vaccineName,
    required DateTime date,
  }) async {
    try {
      logger.i(
          '📅 Scheduling vaccine [$vaccineName] for user [$userName] at $date');

      final reminder = NotificationPayload(
          id: '$vaccineId-main',
          title: '🩺 موعد تطعيم اليوم',
          body: '$userName، اليوم موعد $vaccineName',
          scheduledAt: DateTime(date.year, date.month, date.day, 9));

      final dayBefore = date.subtract(const Duration(days: 1));
      final advance = NotificationPayload(
          id: '$vaccineId-advance',
          title: '📅 تذكير مسبق',
          body: '$userName، غداً موعد $vaccineName',
          scheduledAt:
              DateTime(dayBefore.year, dayBefore.month, dayBefore.day, 18));

      await _notificationService.schedule(reminder);
      await _notificationService.schedule(advance);
      logger.i(
          '✅ Vaccine notifications scheduled: [$vaccineId-main, $vaccineId-advance]');
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
      logger.w('🗑️ Canceling vaccine notifications for [$vaccineId]');

      await _notificationService.cancel('$vaccineId-main');
      await _notificationService.cancel('$vaccineId-advance');

      logger.i('✅ Vaccine notifications canceled for [$vaccineId]');
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
        fromMap: MedicalDatesModel.fromJson,
      );

      if (vaccines == null || vaccines.isEmpty) {
        logger.w('⚠️ No vaccines found for user [$userId]');
        return;
      }

      for (final vaccine in vaccines) {
        final date = DateTime.parse(vaccine.date);
        if (date.isAfter(DateTime.now())) {
          await scheduleVaccine(
            vaccineId: vaccine.id ?? "",
            userName: userName,
            vaccineName: vaccine.name,
            date: date,
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
