import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';

/// Which reminder an item of the feed is.
enum FeedKind {
  /// A vaccine, the evening before (`<doseId>-advance`).
  vaccineEve,

  /// A vaccine, the morning of (`<doseId>-main`).
  vaccineDay,

  /// One of the parent's own reminders (`custom-<id>`).
  custom,
}

/// The part of the notifications screen an item goes in.
enum FeedSection { today, upcoming, earlier }

/// One reminder occurrence: what the phone shows (or will show) at [at].
class FeedItem {
  const FeedItem({
    required this.kind,
    required this.at,
    this.dose,
    this.reminder,
  });

  final FeedKind kind;
  final DateTime at;
  final MedicalDatesModel? dose;
  final ReminderModel? reminder;

  /// The notification key, as `NotificationCoordinator` schedules it.
  String get notificationKey => switch (kind) {
        FeedKind.vaccineEve => '${dose!.id}-advance',
        FeedKind.vaccineDay => '${dose!.id}-main',
        FeedKind.custom => NotificationCoordinator.customKey(reminder!.id!),
      };

  /// Unique per occurrence (a daily reminder fires under the same key every
  /// day), for the read state stored on the device.
  String get key => '$notificationKey@${at.millisecondsSinceEpoch ~/ 60000}';

  /// Whether the phone has shown it: its time has passed.
  bool deliveredBy(DateTime now) => !at.isAfter(now);

  FeedSection sectionAt(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(at.year, at.month, at.day);
    if (day == today) return FeedSection.today;
    return day.isAfter(today) ? FeedSection.upcoming : FeedSection.earlier;
  }
}

/// Builds the notifications screen from the app's own reminders, the same
/// way `NotificationCoordinator` schedules them: two per pending vaccine
/// dose (the evening before at [AppConstant.eveningReminderHour], the
/// morning of at [AppConstant.morningReminderHour]) and the parent's
/// enabled reminders. Nothing is read from the system or stored online.
class NotificationFeed {
  const NotificationFeed._();

  /// How far back "Earlier" goes.
  static const int earlierDays = 7;

  /// How far ahead "Upcoming" goes.
  static const int upcomingDays = 30;

  /// Every item from [since] (when this device started keeping the list)
  /// and at most [earlierDays] back, to [upcomingDays] ahead. A repeating
  /// reminder shows its occurrences today, its latest earlier one and its
  /// next upcoming one, not a row per day.
  static List<FeedItem> build({
    required List<MedicalDatesModel> doses,
    required List<ReminderModel> reminders,
    required DateTime now,
    required DateTime since,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime back = today.subtract(const Duration(days: earlierDays));
    final DateTime from = since.isAfter(back) ? since : back;
    final DateTime tomorrow = DateTime(today.year, today.month, today.day + 1);
    // The end of the last upcoming day.
    final DateTime to =
        DateTime(today.year, today.month, today.day + upcomingDays + 1);
    bool inWindow(DateTime t) => !t.isBefore(from) && t.isBefore(to);

    final List<FeedItem> out = <FeedItem>[];
    for (final MedicalDatesModel d in doses) {
      if ((d.id ?? '').isEmpty) continue;
      final DateTime day = DateTime(d.date.year, d.date.month, d.date.day);
      for (final (FeedKind k, DateTime at) in <(FeedKind, DateTime)>[
        (
          FeedKind.vaccineEve,
          DateTime(
              day.year, day.month, day.day - 1, AppConstant.eveningReminderHour)
        ),
        (
          FeedKind.vaccineDay,
          DateTime(
              day.year, day.month, day.day, AppConstant.morningReminderHour)
        ),
      ]) {
        if (inWindow(at) && _vaccineFires(d, at, now)) {
          out.add(FeedItem(kind: k, at: at, dose: d));
        }
      }
    }

    for (final ReminderModel r in reminders) {
      if (!r.enabled || (r.id ?? '').isEmpty) continue;
      final List<DateTime> times = <DateTime>[];
      DateTime cursor = from.subtract(const Duration(minutes: 1));
      for (int i = 0; i < 64; i++) {
        final DateTime? t = r.nextAfter(cursor);
        if (t == null || !t.isBefore(to)) break;
        if (inWindow(t)) times.add(t);
        cursor = t;
      }
      final List<DateTime> shown = r.repeat == ReminderRepeat.none
          ? times
          : <DateTime>[
              ...times
                  .where((DateTime t) => t.isBefore(today))
                  .toList()
                  .reversed
                  .take(1),
              ...times.where(
                  (DateTime t) => !t.isBefore(today) && t.isBefore(tomorrow)),
              ...times.where((DateTime t) => !t.isBefore(tomorrow)).take(1),
            ];
      for (final DateTime t in shown) {
        out.add(FeedItem(kind: FeedKind.custom, at: t, reminder: r));
      }
    }
    out.sort((FeedItem a, FeedItem b) => a.at.compareTo(b.at));
    return out;
  }

  /// Whether a vaccine reminder at [at] is (or was) on the phone: the dose
  /// is still pending (an upcoming one is scheduled; a past one fired while
  /// it waited), or it was given on or after that day, so it was still
  /// pending when the reminder fired. A skipped dose, or a given one whose
  /// day is unknown or earlier, has none.
  static bool _vaccineFires(MedicalDatesModel d, DateTime at, DateTime now) {
    switch (MedicalDateStateEnum.fromLabel(d.state)) {
      case MedicalDateStateEnum.pending:
        return true;
      case MedicalDateStateEnum.completed:
        final DateTime? g = d.record.givenDate;
        if (g == null || at.isAfter(now)) return false;
        return !DateTime(g.year, g.month, g.day)
            .isBefore(DateTime(at.year, at.month, at.day));
      case MedicalDateStateEnum.skipped:
        return false;
    }
  }
}
