import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/domain/notification_id.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../notification/fake_notification_service.dart';

void main() {
  final DateTime now = DateTime(2027, 3, 10, 12);
  late FakeNotificationService fake;
  late List<ReminderModel> custom;
  late List<MedicalDatesModel> vaccines;
  bool failCustom = false;

  NotificationCoordinator make() {
    fake = FakeNotificationService();
    Get.put<NotificationService>(fake);
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en');
    return NotificationCoordinator(
      clock: () => now,
      loadCustomReminders: (_) async {
        if (failCustom) throw Exception('offline and no cache');
        return custom;
      },
      loadVaccines: (_) async => vaccines,
    )..overrideNotificationService(fake);
  }

  setUp(() {
    failCustom = false;
    custom = <ReminderModel>[];
    vaccines = <MedicalDatesModel>[];
  });
  tearDown(Get.reset);

  ReminderModel r(String id,
          {DateTime? at,
          ReminderRepeat repeat = ReminderRepeat.none,
          bool enabled = true,
          String? note}) =>
      ReminderModel(
          id: id,
          title: 'Vitamin D',
          note: note,
          dateTime: at ?? DateTime(2027, 3, 11, 8),
          repeat: repeat,
          enabled: enabled);

  test('keys are stable and never collide with vaccine keys', () {
    expect(NotificationCoordinator.customKey('abc'), 'custom-abc');
    expect(stableNotificationId(NotificationCoordinator.customKey('abc')),
        stableNotificationId('custom-abc'));
    // A dose and a reminder with the same document id get different keys.
    expect(NotificationCoordinator.customKey('x'),
        isNot(anyOf('x-main', 'x-advance')));
  });

  test('schedules a one-off at its time with the note as body', () async {
    final c = make();
    expect(await c.scheduleCustom(r('a', note: 'one drop')), isTrue);
    final p = fake.store['custom-a']!;
    expect(p.scheduledAt, DateTime(2027, 3, 11, 8));
    expect(p.title, 'Vitamin D');
    expect(p.body, 'one drop');
    expect(p.repeat, NotificationRepeat.none);
  });

  test('no note gives a default body', () async {
    final c = make();
    await c.scheduleCustom(r('a'));
    expect(fake.store['custom-a']!.body, 'A reminder you set in Baby Vax.');
  });

  test('repeating reminders pass their repeat and next time through', () async {
    final c = make();
    await c.scheduleCustom(
        r('d', at: DateTime(2027, 1, 1, 8), repeat: ReminderRepeat.daily));
    await c.scheduleCustom(
        r('w', at: DateTime(2027, 3, 4, 9), repeat: ReminderRepeat.weekly));
    await c.scheduleCustom(
        r('m', at: DateTime(2027, 1, 5, 9), repeat: ReminderRepeat.monthly));
    expect(fake.store['custom-d']!.repeat, NotificationRepeat.daily);
    expect(fake.store['custom-d']!.scheduledAt, DateTime(2027, 3, 11, 8));
    expect(fake.store['custom-w']!.repeat, NotificationRepeat.weekly);
    expect(fake.store['custom-m']!.scheduledAt, DateTime(2027, 4, 5, 9));
  });

  test('skips disabled, past one-off, id-less and far one-off', () async {
    final c = make();
    expect(await c.scheduleCustom(r('a', enabled: false)), isFalse);
    expect(
        await c.scheduleCustom(r('b', at: DateTime(2027, 3, 1, 8))), isFalse);
    expect(
        await c.scheduleCustom(
            ReminderModel(title: 't', dateTime: DateTime(2027, 3, 11))),
        isFalse);
    expect(await c.scheduleCustom(r('c', at: DateTime(2028, 3, 1))), isFalse);
    expect(fake.store, isEmpty);
  });

  test('cancel removes it; re-scheduling replaces, never duplicates', () async {
    final c = make();
    await c.scheduleCustom(r('a'));
    await c.scheduleCustom(r('a', at: DateTime(2027, 3, 12, 8)));
    expect(fake.store.keys.where((k) => k == 'custom-a'), hasLength(1));
    await c.cancelCustom('a');
    expect(fake.store, isEmpty);
  });

  test(
      'sync (app start / reboot) re-schedules custom reminders after '
      'clearing everything', () async {
    custom = <ReminderModel>[r('a'), r('b', enabled: false)];
    vaccines = <MedicalDatesModel>[
      MedicalDatesModel(
          id: 'dose1',
          code: 'measles_1',
          name: 'Measles',
          description: '',
          date: DateTime(2027, 4, 1),
          state: 'Pending'),
    ];
    final c = make();
    await c.syncFromFirestore(userId: 'alice', userName: 'Lina');
    expect(fake.cancelAllCalled, isTrue);
    expect(fake.scheduledIds,
        containsAll(<String>['dose1-main', 'dose1-advance', 'custom-a']));
    expect(fake.scheduledIds, isNot(contains('custom-b')));
  });

  test('custom reminders are restored even with no vaccines', () async {
    custom = <ReminderModel>[r('a')];
    final c = make();
    await c.syncFromFirestore(userId: 'alice', userName: 'Lina');
    expect(fake.scheduledIds, <String>['custom-a']);
  });

  test('a failed custom read keeps the vaccine reminders', () async {
    failCustom = true;
    vaccines = <MedicalDatesModel>[
      MedicalDatesModel(
          id: 'dose1',
          name: 'x',
          description: '',
          date: DateTime(2027, 4, 1),
          state: 'Pending'),
    ];
    final c = make();
    await c.syncFromFirestore(userId: 'alice', userName: 'Lina');
    expect(fake.scheduledIds, containsAll(<String>['dose1-main']));
  });
}
