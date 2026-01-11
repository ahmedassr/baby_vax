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
  }

  // Future<void> cancelVaccine(String vaccineId) async {
  //   await _notificationService.cancel('$vaccineId-main');
  //   await _notificationService.cancel('$vaccineId-advance');
  // }

  Future<void> rescheduleAllVaccines({
    required String userId,
    required String userName,
  }) async {
    await _notificationService.cancelAll();

    final vaccines =
        await AppConstant.fireStoreHelper.fetchData<MedicalDatesModel>(
      path: ['users', userId, 'medical_dates'],
      fromMap: MedicalDatesModel.fromJson,
    );

    if (vaccines != null) {
      for (final vaccine in vaccines) {
        final date = DateTime.parse(vaccine.date);
        if (date.isAfter(DateTime.now())) {
          await scheduleVaccine(
            vaccineId: vaccine.id ?? "",
            userName: userName,
            vaccineName: vaccine.name,
            date: date,
          );
        }
      }
    }
  }
}
