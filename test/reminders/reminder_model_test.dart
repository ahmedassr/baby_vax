import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2027, 3, 10, 12); // a Wednesday

  ReminderModel r(DateTime at, ReminderRepeat repeat) =>
      ReminderModel(title: 't', dateTime: at, repeat: repeat);

  test('a future reminder fires at its own time', () {
    final at = DateTime(2027, 3, 11, 9);
    for (final rep in ReminderRepeat.values) {
      expect(r(at, rep).nextAfter(now), at);
    }
  });

  test('a past one-off reminder has no next time', () {
    expect(
        r(DateTime(2027, 3, 9, 9), ReminderRepeat.none).nextAfter(now), isNull);
  });

  test('daily: today if still ahead, else tomorrow, same clock time', () {
    expect(r(DateTime(2027, 1, 1, 18, 30), ReminderRepeat.daily).nextAfter(now),
        DateTime(2027, 3, 10, 18, 30));
    expect(r(DateTime(2027, 1, 1, 8), ReminderRepeat.daily).nextAfter(now),
        DateTime(2027, 3, 11, 8));
  });

  test('weekly: next same weekday', () {
    // 4 Mar 2027 is a Thursday.
    expect(r(DateTime(2027, 3, 4, 9), ReminderRepeat.weekly).nextAfter(now),
        DateTime(2027, 3, 11, 9));
    // Same weekday as now but earlier in the day: next week.
    expect(r(DateTime(2027, 3, 3, 9), ReminderRepeat.weekly).nextAfter(now),
        DateTime(2027, 3, 17, 9));
  });

  test('monthly: same day, clamped in short months', () {
    expect(r(DateTime(2027, 1, 5, 9), ReminderRepeat.monthly).nextAfter(now),
        DateTime(2027, 4, 5, 9));
    expect(
        r(DateTime(2027, 1, 31, 9), ReminderRepeat.monthly)
            .nextAfter(DateTime(2027, 4, 1)),
        DateTime(2027, 4, 30, 9));
  });

  test('round-trips through the map, in the rules\' names', () {
    final m = ReminderModel(
            title: '  Doctor ',
            dateTime: DateTime(2027, 4, 1, 10),
            note: ' ',
            repeat: ReminderRepeat.weekly,
            enabled: false)
        .toMap();
    expect(m.keys.toSet(), <String>{'title', 'dateTime', 'repeat', 'enabled'});
    expect(m['title'], 'Doctor');
    expect(m['dateTime'], isA<Timestamp>());
    final back = ReminderModel.fromMap(m, 'r1');
    expect(back.repeat, ReminderRepeat.weekly);
    expect(back.enabled, isFalse);
    expect(
        ReminderModel.fromMap(<String, dynamic>{'repeat': 'yearly'}, 'x')
            .repeat,
        ReminderRepeat.none);
  });

  test('account deletion walks the reminders collection', () {
    expect(AppPath.userSubcollections('u'), contains('users/u/reminders'));
  });
}
