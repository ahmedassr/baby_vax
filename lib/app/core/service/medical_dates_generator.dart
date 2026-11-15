import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

/// Thrown when a birth date cannot be used to build a schedule.
class InvalidBirthDateException implements Exception {
  InvalidBirthDateException(this.reason);

  final String reason;

  @override
  String toString() => 'InvalidBirthDateException: $reason';
}

/// One entry in the immunization schedule.
class VaccineScheduleEntry {
  const VaccineScheduleEntry({
    required this.code,
    required this.months,
    required this.name,
    required this.description,
  });

  /// Stable identifier, independent of the display text. Persisted alongside
  /// the record so the name and description can be localized at display time
  /// without rewriting documents that were created in another language.
  final String code;

  /// Age in whole months at which the dose is due. 0 means at birth.
  final int months;

  final String name;
  final String description;
}

/// Builds a child's vaccination schedule from their birth date.
///
/// Schedule source
/// ---------------
/// Modelled on the Palestinian Ministry of Health routine childhood
/// immunization schedule, which follows the WHO EPI recommendations. It is
/// informational only: the in-app disclaimer tells parents to follow their own
/// doctor and their country's national schedule, which differ between
/// countries and change over time.
///
/// Date arithmetic
/// ---------------
/// Offsets are in **calendar months**, applied with [addMonths]. The previous
/// implementation used fixed `Duration(days:)` offsets, which were wrong in
/// three ways:
///   * 12 months was written as 350 days — about two weeks early;
///   * year offsets used `365 * n`, so the 5-, 11- and 15-year doses drifted
///     1–4 days early as leap days accumulated;
///   * adding a `Duration` to a local `DateTime` shifts by absolute hours, so
///     crossing a DST boundary moved the appointment's time of day, and could
///     move it onto the previous or next calendar day.
class MedicalDatesGenerator {
  /// The routine schedule. Order is chronological.
  static const List<VaccineScheduleEntry> schedule = <VaccineScheduleEntry>[
    VaccineScheduleEntry(
      code: 'bcg_hepb_birth',
      months: 0,
      name: 'BCG and Hepatitis B (1st dose)',
      description:
          'Protects against tuberculosis and hepatitis B. Given at birth.',
    ),
    VaccineScheduleEntry(
      code: 'penta_opv_pcv_1',
      months: 2,
      name: 'First DTP-HepB-Hib, Polio and Pneumococcal',
      description:
          'Prevents diphtheria, tetanus, whooping cough, hepatitis B, Hib, polio, and pneumonia. Given at 2 months.',
    ),
    VaccineScheduleEntry(
      code: 'penta_opv_pcv_2',
      months: 4,
      name: 'Second DTP-HepB-Hib, Polio and Pneumococcal',
      description: 'Second dose to strengthen protection. Given at 4 months.',
    ),
    VaccineScheduleEntry(
      code: 'penta_opv_pcv_3',
      months: 6,
      name: 'Third DTP-HepB-Hib, Polio and Pneumococcal',
      description: 'Final primary dose of early vaccines. Given at 6 months.',
    ),
    VaccineScheduleEntry(
      code: 'measles_1',
      months: 9,
      name: 'Measles (1st dose)',
      description: 'Protects against measles. Given at 9 months.',
    ),
    VaccineScheduleEntry(
      code: 'mmr_varicella_pcv_booster',
      months: 12,
      name: 'MMR, Varicella and Pneumococcal Booster',
      description:
          'Protects against measles, mumps, rubella, chickenpox, and boosts pneumonia protection. Given at 12 months.',
    ),
    VaccineScheduleEntry(
      code: 'penta_opv_mmr_2_booster',
      months: 18,
      name: 'Booster DTP-HepB-Hib, Polio and MMR (2nd dose)',
      description:
          'Booster for earlier vaccines and second dose of MMR. Given at 18 months.',
    ),
    VaccineScheduleEntry(
      code: 'school_entry_boosters',
      months: 60, // 5 years
      name: 'School Entry Boosters: DTP + Polio + Varicella (2nd dose)',
      description:
          'Boosters to protect before school: diphtheria, tetanus, polio, chickenpox. Given around 5 years.',
    ),
    VaccineScheduleEntry(
      code: 'hpv',
      months: 132, // 11 years
      name: 'HPV Vaccine',
      description:
          'Protects against human papillomavirus. Given at age 10-12, mostly for girls (sometimes boys).',
    ),
    VaccineScheduleEntry(
      code: 'td_booster',
      months: 180, // 15 years
      name: 'Td Booster (Tetanus & Diphtheria)',
      description:
          'Teenage booster for tetanus and diphtheria. Given at age 15.',
    ),
  ];

  /// Oldest birth date accepted. Beyond this the whole schedule is already in
  /// the past and the app has nothing useful to show.
  static const int maxAgeYears = 18;

  /// Builds the schedule for [birthDateStr].
  ///
  /// [birthDateStr] must be an ISO-8601 date or date-time, which is what the
  /// sign-up form produces (`yyyy-MM-dd HH:mm:ss`).
  ///
  /// Throws [InvalidBirthDateException] for unparseable input, a date in the
  /// future, or a child older than [maxAgeYears]. Callers surface this as a
  /// form error rather than writing a nonsense schedule to Firestore.
  ///
  /// Appointment dates are date-only (midnight local). A vaccination is due on
  /// a day, not at an instant; the reminder times come from
  /// `AppConstant.morningReminderHour` / `eveningReminderHour`. The old code
  /// added an unexplained 5 hours to the birth dose and otherwise carried the
  /// exact minute of birth forward 15 years.
  static List<MedicalDatesModel> generator(String birthDateStr,
      {DateTime? now}) {
    final DateTime birthDate = parseBirthDate(birthDateStr, now: now);
    final String pendingState = MedicalDateStateEnum.pending.label;

    return schedule
        .map((VaccineScheduleEntry entry) => MedicalDatesModel(
              code: entry.code,
              name: entry.name,
              description: entry.description,
              date: addMonths(birthDate, entry.months),
              state: pendingState,
            ))
        .toList(growable: false);
  }

  /// Parses and validates a birth date, normalized to midnight local time.
  static DateTime parseBirthDate(String birthDateStr, {DateTime? now}) {
    final String trimmed = birthDateStr.trim();
    if (trimmed.isEmpty) {
      throw InvalidBirthDateException('Birth date is empty');
    }

    final DateTime? parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      throw InvalidBirthDateException('Birth date is not a valid date: '
          '"$birthDateStr"');
    }

    final DateTime today = _atMidnight(now ?? DateTime.now());
    final DateTime birthDay = _atMidnight(parsed);

    if (birthDay.isAfter(today)) {
      throw InvalidBirthDateException('Birth date is in the future');
    }
    if (birthDay.isBefore(addMonths(today, -maxAgeYears * 12))) {
      throw InvalidBirthDateException(
          'Birth date is more than $maxAgeYears years ago');
    }

    return birthDay;
  }

  static DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [doses] moved to a corrected birth date.
  ///
  /// Used when a parent fixes a wrong date of birth in the profile. Each
  /// generated dose (one with a known schedule `code`) gets the date it
  /// would have had from [birthDate]; its state and everything else it
  /// carries are kept. Doses without a known code are returned unchanged,
  /// since there is no rule for where they belong.
  ///
  /// Only doses whose date actually changes are returned, so the caller
  /// writes nothing for a no-op edit.
  static List<MedicalDatesModel> rebase(
      Iterable<MedicalDatesModel> doses, DateTime birthDate) {
    final DateTime birth = _atMidnight(birthDate);
    final Map<String, int> months = <String, int>{
      for (final VaccineScheduleEntry e in schedule) e.code: e.months,
    };
    final List<MedicalDatesModel> moved = <MedicalDatesModel>[];
    for (final MedicalDatesModel d in doses) {
      final int? m = d.code == null ? null : months[d.code];
      if (m == null) continue;
      final DateTime date = addMonths(birth, m);
      if (date != _atMidnight(d.date)) moved.add(d.copyWith(date: date));
    }
    return moved;
  }

  /// Adds [months] calendar months to [from], clamping the day to the target
  /// month's length.
  ///
  /// 31 January + 1 month is 28 February (29 in a leap year), not 3 March.
  /// Accepts negative [months].
  static DateTime addMonths(DateTime from, int months) {
    final int zeroBasedMonth = from.month - 1 + months;
    // Floor division so negative offsets roll the year back correctly.
    final int yearShift = (zeroBasedMonth / 12).floor();
    final int year = from.year + yearShift;
    final int month = zeroBasedMonth - yearShift * 12 + 1;

    // Day 0 of month+1 is the last day of `month`.
    final int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final int day = from.day <= lastDayOfMonth ? from.day : lastDayOfMonth;

    return DateTime(year, month, day);
  }
}
