import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart'
    show pluralCategory;
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:get/get.dart';

import '../../config/themes/app_status_colors.dart';

/// Counts and the "next thing to do" for a child's schedule, on [now]'s day.
///
/// Pure: built from the dose list the screens already have, so the home
/// screen no longer needs its own Firestore query (v1.0 ran a
/// `state == Pending && date >= today` query just for the next dose, which
/// also meant an overdue dose was never shown there).
class ScheduleSummary {
  ScheduleSummary(Iterable<MedicalDatesModel> doses, this.now)
      : doses = List<MedicalDatesModel>.unmodifiable(doses);

  final List<MedicalDatesModel> doses;
  final DateTime now;

  DoseDisplayStatus _status(MedicalDatesModel d) =>
      VaccineStatePolicy.displayStatus(d, now);

  int _count(DoseDisplayStatus s) => doses.where((d) => _status(d) == s).length;

  int get total => doses.length;
  int get completed => _count(DoseDisplayStatus.completed);
  int get skipped => _count(DoseDisplayStatus.skipped);
  int get overdue => _count(DoseDisplayStatus.overdue);
  int get pending => _count(DoseDisplayStatus.pending);

  /// Doses that count towards progress: everything except skipped ones, so
  /// a parent who skipped a dose can still reach "all done".
  int get countable => total - skipped;

  bool get allDone => total > 0 && completed == countable;

  /// The dose the home screen leads with: the oldest overdue dose if there
  /// is one (it needs attention first), otherwise the next pending one.
  /// Null when nothing is left to do.
  MedicalDatesModel? get hero {
    final List<MedicalDatesModel> byDate = doses.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final DoseDisplayStatus wanted in <DoseDisplayStatus>[
      DoseDisplayStatus.overdue,
      DoseDisplayStatus.pending,
    ]) {
      for (final MedicalDatesModel d in byDate) {
        if (_status(d) == wanted) return d;
      }
    }
    return null;
  }

  /// The doses to show for [filter]; all of them for null.
  List<MedicalDatesModel> filtered(DoseDisplayStatus? filter) => filter == null
      ? doses
      : doses.where((d) => _status(d) == filter).toList();
}

/// Doses due at the same age: "At birth", "2 months", "5 years".
class AgeGroup {
  const AgeGroup(this.months, this.doses);

  /// Age in whole months; null for doses whose age is unknown (a custom
  /// date on a profile with no birth date).
  final int? months;
  final List<MedicalDatesModel> doses;

  /// The heading, with the CLDR plural form for the current language.
  String get label => ageLabel(months);
}

/// "At birth", "2 months", "18 months", "5 years" — or "Other dates".
///
/// Under two years ages are said in months (that is how the schedule and
/// clinics say them); from two years, in whole years when exact.
String ageLabel(int? months) {
  if (months == null) return "age_other".tr;
  if (months == 0) return "age_at_birth".tr;
  if (months < 24 || months % 12 != 0) return _plural('age_months', months);
  return _plural('age_years', months ~/ 12);
}

String _plural(String base, int count) {
  final String category =
      pluralCategory(count, Get.locale?.languageCode ?? 'en');
  String key = '${base}_$category';
  if (key.tr == key) key = '${base}_other';
  return key.trParams(<String, String>{'count': '$count'});
}

/// Groups [doses] by the age they are due at, youngest first.
///
/// Generated doses know their age from their schedule `code`. Anything else
/// is placed by whole calendar months between [birthday] and its date, so a
/// dose added by hand at "2 months" lands with the generated 2-month doses.
/// Within a group the schedule's date order is kept.
List<AgeGroup> groupByAge(
  Iterable<MedicalDatesModel> doses, {
  DateTime? birthday,
}) {
  final Map<String, int> monthsByCode = <String, int>{
    for (final VaccineScheduleEntry e in MedicalDatesGenerator.schedule)
      e.code: e.months,
  };

  int? monthsOf(MedicalDatesModel d) {
    final int? known = d.code == null ? null : monthsByCode[d.code];
    if (known != null) return known;
    if (birthday == null) return null;
    int m = (d.date.year - birthday.year) * 12 + d.date.month - birthday.month;
    if (d.date.day < birthday.day) m -= 1;
    return m < 0 ? 0 : m;
  }

  final Map<int?, List<MedicalDatesModel>> buckets =
      <int?, List<MedicalDatesModel>>{};
  for (final MedicalDatesModel d in doses) {
    buckets.putIfAbsent(monthsOf(d), () => <MedicalDatesModel>[]).add(d);
  }
  final List<int?> keys = buckets.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });
  return <AgeGroup>[
    for (final int? k in keys)
      AgeGroup(k, buckets[k]!..sort((a, b) => a.date.compareTo(b.date))),
  ];
}
