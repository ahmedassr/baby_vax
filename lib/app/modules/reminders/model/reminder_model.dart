import 'package:baby_vax/app/core/imports/import_library.dart';

/// How often a custom reminder repeats.
enum ReminderRepeat {
  none,
  daily,
  weekly,
  monthly;

  /// The stored value; must match the rules' list.
  String get value => name;

  static ReminderRepeat fromValue(Object? v) => ReminderRepeat.values
      .firstWhere((r) => r.value == v, orElse: () => ReminderRepeat.none);
}

/// A reminder or appointment the parent adds: a doctor visit, vitamin D
/// drops, a follow-up. `users/{uid}/reminders/{id}`.
class ReminderModel {
  const ReminderModel({
    this.id,
    required this.title,
    required this.dateTime,
    this.note,
    this.repeat = ReminderRepeat.none,
    this.enabled = true,
  });

  final String? id;
  final String title;

  /// When it fires (first time, for a repeating reminder). Local wall-clock.
  final DateTime dateTime;
  final String? note;
  final ReminderRepeat repeat;

  /// Off keeps the reminder in the list but schedules nothing.
  final bool enabled;

  static const int maxTitle = 100;
  static const int maxNote = 500;

  ReminderModel copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? note,
    ReminderRepeat? repeat,
    bool? enabled,
  }) =>
      ReminderModel(
        id: id ?? this.id,
        title: title ?? this.title,
        dateTime: dateTime ?? this.dateTime,
        note: note ?? this.note,
        repeat: repeat ?? this.repeat,
        enabled: enabled ?? this.enabled,
      );

  /// The next time it should fire at or after [now], or null when a
  /// one-off reminder is already past.
  DateTime? nextAfter(DateTime now) {
    if (dateTime.isAfter(now)) return dateTime;
    switch (repeat) {
      case ReminderRepeat.none:
        return null;
      case ReminderRepeat.daily:
        DateTime t = DateTime(
            now.year, now.month, now.day, dateTime.hour, dateTime.minute);
        if (!t.isAfter(now)) {
          t = DateTime(t.year, t.month, t.day + 1, t.hour, t.minute);
        }
        return t;
      case ReminderRepeat.weekly:
        DateTime t = DateTime(
            now.year, now.month, now.day, dateTime.hour, dateTime.minute);
        while (t.weekday != dateTime.weekday || !t.isAfter(now)) {
          t = DateTime(t.year, t.month, t.day + 1, t.hour, t.minute);
        }
        return t;
      case ReminderRepeat.monthly:
        // The same day of the month, clamped in short months (31st -> 30th).
        DateTime candidate(int y, int m) {
          final int last = DateTime(y, m + 1, 0).day;
          final int d = dateTime.day <= last ? dateTime.day : last;
          return DateTime(y, m, d, dateTime.hour, dateTime.minute);
        }
        DateTime t = candidate(now.year, now.month);
        int y = now.year, m = now.month;
        while (!t.isAfter(now)) {
          m++;
          if (m > 12) {
            m = 1;
            y++;
          }
          t = candidate(y, m);
        }
        return t;
    }
  }

  factory ReminderModel.fromMap(Map<String, dynamic> data, String? id) {
    final Object? t = data['dateTime'];
    final Object? note = data['note'];
    return ReminderModel(
      id: id,
      title: (data['title'] as String?) ?? '',
      dateTime: t is Timestamp
          ? t.toDate()
          : t is DateTime
              ? t
              : DateTime.fromMillisecondsSinceEpoch(0),
      note: note is String && note.trim().isNotEmpty ? note : null,
      repeat: ReminderRepeat.fromValue(data['repeat']),
      enabled: data['enabled'] is bool ? data['enabled'] as bool : true,
    );
  }

  factory ReminderModel.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    return ReminderModel.fromMap(
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{}, doc.id);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title.trim(),
        'dateTime': Timestamp.fromDate(dateTime),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        'repeat': repeat.value,
        'enabled': enabled,
      };
}
