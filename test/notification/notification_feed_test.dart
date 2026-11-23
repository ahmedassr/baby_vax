import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/application/notification_feed.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  // fixedNow: Wednesday 10 Mar 2027, noon.
  final DateTime since = DateTime(2027, 3, 1);

  MedicalDatesModel dose(String id, DateTime date,
          {String state = 'Pending', DateTime? given}) =>
      sampleSchedule()[1].copyWith(
          id: id,
          date: date,
          state: state,
          record: given == null ? null : DoseRecord(givenDate: given));

  List<FeedItem> build(
          {List<MedicalDatesModel> doses = const <MedicalDatesModel>[],
          List<ReminderModel> reminders = const <ReminderModel>[],
          DateTime? from}) =>
      NotificationFeed.build(
          doses: doses,
          reminders: reminders,
          now: fixedNow,
          since: from ?? since);

  test('a pending dose: the evening before and the morning of', () {
    final List<FeedItem> f = build(doses: <MedicalDatesModel>[
      dose('d1', DateTime(2027, 3, 15)),
    ]);
    expect(f.map((i) => i.at), <DateTime>[
      DateTime(2027, 3, 14, AppConstant.eveningReminderHour),
      DateTime(2027, 3, 15, AppConstant.morningReminderHour),
    ]);
    expect(f.map((i) => i.notificationKey), <String>['d1-advance', 'd1-main']);
    expect(
        f.every((i) => i.sectionAt(fixedNow) == FeedSection.upcoming), isTrue);
    expect(f.any((i) => i.deliveredBy(fixedNow)), isFalse);
  });

  test('past reminders of a still-pending dose were delivered', () {
    final List<FeedItem> f =
        build(doses: <MedicalDatesModel>[dose('d1', DateTime(2027, 3, 8))]);
    expect(f, hasLength(2));
    expect(f.every((i) => i.deliveredBy(fixedNow)), isTrue);
    expect(
        f.every((i) => i.sectionAt(fixedNow) == FeedSection.earlier), isTrue);
  });

  test('today: delivered this morning', () {
    final List<FeedItem> f =
        build(doses: <MedicalDatesModel>[dose('d1', DateTime(2027, 3, 10))]);
    final FeedItem day = f.last;
    expect(day.sectionAt(fixedNow), FeedSection.today);
    expect(day.deliveredBy(fixedNow), isTrue);
  });

  test('given doses: only reminders that fired while it was pending', () {
    expect(
        build(doses: <MedicalDatesModel>[
          dose('d1', DateTime(2027, 3, 8),
              state: 'Completed', given: DateTime(2027, 3, 8))
        ]).length,
        2,
        reason: 'given on the day: both had fired');
    expect(
        build(doses: <MedicalDatesModel>[
          dose('d1', DateTime(2027, 3, 8),
              state: 'Completed', given: DateTime(2027, 3, 7))
        ]).map((i) => i.notificationKey),
        <String>['d1-advance'],
        reason: 'given the day before: the morning one was cancelled');
    expect(
        build(doses: <MedicalDatesModel>[
          dose('d1', DateTime(2027, 3, 15),
              state: 'Completed', given: DateTime(2027, 3, 9))
        ]),
        isEmpty,
        reason: 'given early: none fire');
    expect(
        build(doses: <MedicalDatesModel>[
          dose('d1', DateTime(2027, 3, 8), state: 'Skipped'),
          dose('d2', DateTime(2027, 3, 8), state: 'Completed'),
        ]),
        isEmpty);
  });

  test('nothing before this device started the list, nor beyond the window',
      () {
    expect(
        build(
            doses: <MedicalDatesModel>[dose('d1', DateTime(2027, 3, 8))],
            from: DateTime(2027, 3, 10, 8)),
        isEmpty);
    expect(build(doses: <MedicalDatesModel>[dose('d1', DateTime(2027, 2, 20))]),
        isEmpty,
        reason: 'more than 7 days ago');
    expect(build(doses: <MedicalDatesModel>[dose('d1', DateTime(2027, 5, 15))]),
        isEmpty,
        reason: 'more than 30 days ahead');
  });

  test('a daily reminder: today, its last earlier and next upcoming', () {
    final List<FeedItem> f = build(reminders: <ReminderModel>[
      ReminderModel(
          id: 'r1',
          title: 'Vitamin D',
          dateTime: DateTime(2027, 2, 1, 8),
          repeat: ReminderRepeat.daily),
    ]);
    expect(f.map((i) => i.at), <DateTime>[
      DateTime(2027, 3, 9, 8),
      DateTime(2027, 3, 10, 8),
      DateTime(2027, 3, 11, 8),
    ]);
    expect(f.map((i) => i.notificationKey).toSet(), <String>{'custom-r1'});
    expect(f.map((i) => i.key).toSet(), hasLength(3),
        reason: 'one read state per occurrence');
  });

  test('one-off and disabled reminders', () {
    final List<FeedItem> f = build(reminders: <ReminderModel>[
      ReminderModel(
          id: 'a', title: 'Doctor', dateTime: DateTime(2027, 3, 12, 10)),
      ReminderModel(id: 'b', title: 'Old', dateTime: DateTime(2027, 3, 9, 10)),
      ReminderModel(
          id: 'c',
          title: 'Off',
          dateTime: DateTime(2027, 3, 11, 10),
          enabled: false),
    ]);
    expect(f.map((i) => i.reminder!.id), <String>['b', 'a']);
    expect(f.first.deliveredBy(fixedNow), isTrue);
  });
}
