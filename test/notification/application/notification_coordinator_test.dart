import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_notification_service.dart';

/// Covers the reminder guarantees the release depends on: stable ids, no
/// duplicates on re-sync, nothing scheduled in the past or beyond the horizon,
/// and a clean slate on logout.
void main() {
  late FakeNotificationService fakeService;
  late NotificationCoordinator coordinator;

  /// Fixed "now" so horizon and past-date assertions never depend on the wall
  /// clock when the suite happens to run. Midday, so a same-day 09:00 reminder
  /// is unambiguously in the past and an 18:00 one unambiguously ahead.
  final DateTime fixedNow = DateTime(2026, 6, 15, 12, 0);

  setUp(() {
    fakeService = FakeNotificationService();
    Get.put<NotificationService>(fakeService);
    // Real translations, so the reminder text assertions check the actual
    // localized strings rather than untranslated keys.
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en');
    coordinator = NotificationCoordinator(clock: () => fixedNow);
    coordinator.overrideNotificationService(fakeService);
  });

  tearDown(Get.reset);

  /// A date safely inside the scheduling horizon.
  DateTime inWindow() => fixedNow.add(const Duration(days: 30));

  group('scheduleVaccine', () {
    test('schedules an advance and a main reminder', () async {
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: inWindow(),
      );

      expect(fakeService.scheduledIds, <String>['vax_1-advance', 'vax_1-main']);
    });

    test('puts the main reminder on the appointment day at the morning hour',
        () async {
      final DateTime date = inWindow();

      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: date,
      );

      final NotificationPayload main = fakeService.store['vax_1-main']!;
      expect(main.scheduledAt.year, date.year);
      expect(main.scheduledAt.month, date.month);
      expect(main.scheduledAt.day, date.day);
      expect(main.scheduledAt.hour, AppConstant.morningReminderHour);
    });

    test('puts the advance reminder on the previous day at the evening hour',
        () async {
      final DateTime date = inWindow();
      final DateTime expected = date.subtract(const Duration(days: 1));

      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: date,
      );

      final NotificationPayload advance = fakeService.store['vax_1-advance']!;
      expect(advance.scheduledAt.year, expected.year);
      expect(advance.scheduledAt.month, expected.month);
      expect(advance.scheduledAt.day, expected.day);
      expect(advance.scheduledAt.hour, AppConstant.eveningReminderHour);
    });

    test('re-scheduling the same vaccine does not duplicate reminders',
        () async {
      final DateTime date = inWindow();

      for (int i = 0; i < 3; i++) {
        await coordinator.scheduleVaccine(
          vaccineId: 'vax_1',
          userName: 'Baby',
          vaccineName: 'HepB',
          date: date,
        );
      }

      // schedule() was called six times, but ids are stable so only two
      // reminders exist. This is the duplicate-notification guarantee.
      expect(fakeService.scheduleCallCount, 6);
      expect(fakeService.scheduledIds.length, 2);
    });

    test('skips a vaccine whose date has passed', () async {
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_past',
        userName: 'Baby',
        vaccineName: 'BCG',
        date: fixedNow.subtract(const Duration(days: 10)),
      );

      expect(fakeService.scheduledIds, isEmpty);
    });

    test('skips a vaccine beyond the horizon, leaving it for a later top-up',
        () async {
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_far',
        userName: 'Baby',
        vaccineName: 'Td Booster',
        date: fixedNow.add(const Duration(days: 365 * 10)),
      );

      expect(fakeService.scheduledIds, isEmpty);
    });

    test('schedules both reminders when the appointment is tomorrow', () async {
      // At 12:00 today, the evening-before reminder (today 18:00) is still
      // ahead, as is tomorrow 09:00.
      final DateTime date = DateTime(
          fixedNow.year, fixedNow.month, fixedNow.day + 1);

      await coordinator.scheduleVaccine(
        vaccineId: 'vax_soon',
        userName: 'Baby',
        vaccineName: 'Polio',
        date: date,
      );

      expect(fakeService.scheduledIds,
          <String>['vax_soon-advance', 'vax_soon-main']);
    });

    test('schedules nothing when the appointment is today and both times have '
        'passed', () async {
      // advance = yesterday 18:00, main = today 09:00; "now" is today 12:00.
      final DateTime date =
          DateTime(fixedNow.year, fixedNow.month, fixedNow.day);

      await coordinator.scheduleVaccine(
        vaccineId: 'vax_today',
        userName: 'Baby',
        vaccineName: 'BCG',
        date: date,
      );

      expect(fakeService.scheduledIds, isEmpty);
    });

    test('schedules reminders exactly at the horizon edge but not past it',
        () async {
      // 6 months ahead, calendar-correct: inside. A day later: outside.
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_edge_in',
        userName: 'Baby',
        vaccineName: 'Edge in',
        date: DateTime(2026, 12, 14, 12, 0),
      );
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_edge_out',
        userName: 'Baby',
        vaccineName: 'Edge out',
        date: DateTime(2026, 12, 16, 12, 0),
      );

      expect(fakeService.scheduledIds, contains('vax_edge_in-main'));
      expect(fakeService.scheduledIds, isNot(contains('vax_edge_out-main')));
    });

    test('refuses an empty vaccine id rather than colliding ids', () async {
      await coordinator.scheduleVaccine(
        vaccineId: '',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: inWindow(),
      );

      expect(fakeService.scheduledIds, isEmpty);
    });

    test('includes the child and vaccine name in the reminder body', () async {
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Lina',
        vaccineName: 'Measles',
        date: inWindow(),
      );

      final NotificationPayload main = fakeService.store['vax_1-main']!;
      expect(main.body, contains('Lina'));
      expect(main.body, contains('Measles'));
    });
  });

  group('cancelVaccine', () {
    test('removes both reminders for that vaccine only', () async {
      final DateTime date = inWindow();
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: date,
      );
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_2',
        userName: 'Baby',
        vaccineName: 'Polio',
        date: date,
      );

      await coordinator.cancelVaccine('vax_1');

      expect(fakeService.scheduledIds, <String>['vax_2-advance', 'vax_2-main']);
    });

    test('is a no-op for a vaccine with no reminders', () async {
      await coordinator.cancelVaccine('never_scheduled');
      expect(fakeService.scheduledIds, isEmpty);
    });
  });

  group('cancelAllReminders', () {
    test('clears everything, as logout and account deletion require', () async {
      await coordinator.scheduleVaccine(
        vaccineId: 'vax_1',
        userName: 'Baby',
        vaccineName: 'HepB',
        date: inWindow(),
      );

      await coordinator.cancelAllReminders();

      expect(fakeService.cancelAllCalled, isTrue);
      expect(fakeService.scheduledIds, isEmpty);
    });
  });

  group('requestPermission', () {
    test('passes the grant through', () async {
      fakeService.permissionGranted = true;
      expect(await coordinator.requestPermission(), isTrue);
    });

    test('passes a denial through', () async {
      fakeService.permissionGranted = false;
      expect(await coordinator.requestPermission(), isFalse);
    });
  });

  group('syncFromFirestore', () {
    test('does nothing without a signed-in user', () async {
      await coordinator.syncFromFirestore(userId: '', userName: 'Baby');

      // Importantly it does NOT cancel: a missing uid must not wipe the
      // reminders of whoever is actually signed in.
      expect(fakeService.cancelAllCalled, isFalse);
      expect(fakeService.scheduledIds, isEmpty);
    });
  });
}
