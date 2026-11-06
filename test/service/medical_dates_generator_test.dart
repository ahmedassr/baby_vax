import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed reference date so "today" never affects the assertions.
  final DateTime now = DateTime(2026, 6, 15, 12, 0);

  group('addMonths', () {
    test('adds whole months', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 1, 10), 2),
          DateTime(2026, 3, 10));
    });

    test('rolls over the year', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 11, 10), 3),
          DateTime(2027, 2, 10));
    });

    test('clamps 31 Jan + 1 month to the end of February', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 1, 31), 1),
          DateTime(2026, 2, 28));
    });

    test('clamps to 29 February in a leap year', () {
      // 2028 is a leap year.
      expect(MedicalDatesGenerator.addMonths(DateTime(2028, 1, 31), 1),
          DateTime(2028, 2, 29));
    });

    test('clamps 31 May + 1 month to 30 June', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 5, 31), 1),
          DateTime(2026, 6, 30));
    });

    test('handles negative offsets, rolling the year back', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 2, 10), -3),
          DateTime(2025, 11, 10));
    });

    test('negative offset of a whole year', () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 6, 15), -12),
          DateTime(2025, 6, 15));
    });

    test('a 29 February birth date lands on 28 February in a non-leap year',
        () {
      expect(MedicalDatesGenerator.addMonths(DateTime(2024, 2, 29), 12),
          DateTime(2025, 2, 28));
    });

    test('is exact across 15 years, where day-based maths drifts', () {
      // 180 months after 15 Jun 2026 is 15 Jun 2041 exactly.
      expect(MedicalDatesGenerator.addMonths(DateTime(2026, 6, 15), 180),
          DateTime(2041, 6, 15));
      // The old implementation used 15 * 365 days, which lands 4 days early
      // because of the leap days in between.
      final DateTime dayBased =
          DateTime(2026, 6, 15).add(const Duration(days: 15 * 365));
      expect(dayBased, DateTime(2041, 6, 11));
    });
  });

  group('parseBirthDate', () {
    test('accepts the sign-up form format and normalizes to midnight', () {
      expect(
        MedicalDatesGenerator.parseBirthDate('2026-03-01 14:35:09', now: now),
        DateTime(2026, 3, 1),
      );
    });

    test('accepts a plain ISO date', () {
      expect(MedicalDatesGenerator.parseBirthDate('2026-03-01', now: now),
          DateTime(2026, 3, 1));
    });

    test('accepts today', () {
      expect(MedicalDatesGenerator.parseBirthDate('2026-06-15', now: now),
          DateTime(2026, 6, 15));
    });

    test('rejects an empty string', () {
      expect(() => MedicalDatesGenerator.parseBirthDate('', now: now),
          throwsA(isA<InvalidBirthDateException>()));
    });

    test('rejects unparseable input instead of throwing FormatException', () {
      // DateTime.parse would have thrown a raw FormatException here, which
      // nothing caught.
      expect(() => MedicalDatesGenerator.parseBirthDate('not a date', now: now),
          throwsA(isA<InvalidBirthDateException>()));
    });

    test('rejects a future birth date', () {
      expect(
          () => MedicalDatesGenerator.parseBirthDate('2026-06-16', now: now),
          throwsA(isA<InvalidBirthDateException>()));
    });

    test('rejects a child older than the schedule', () {
      expect(() => MedicalDatesGenerator.parseBirthDate('2000-01-01', now: now),
          throwsA(isA<InvalidBirthDateException>()));
    });
  });

  group('generator', () {
    late List<MedicalDatesModel> result;

    setUp(() {
      result = MedicalDatesGenerator.generator('2026-06-15 03:47:00', now: now);
    });

    test('produces one record per schedule entry', () {
      expect(result.length, MedicalDatesGenerator.schedule.length);
      expect(result.length, 10);
    });

    test('every record starts pending', () {
      expect(
        result.every((MedicalDatesModel m) =>
            m.state == MedicalDateStateEnum.pending.label),
        isTrue,
      );
    });

    test('every record carries a stable code', () {
      expect(result.every((MedicalDatesModel m) => m.code != null), isTrue);
      // Codes are unique, so they can key localization and dedupe.
      expect(result.map((MedicalDatesModel m) => m.code).toSet().length, 10);
    });

    test('dates are chronological', () {
      for (int i = 1; i < result.length; i++) {
        expect(result[i].date.isAfter(result[i - 1].date), isTrue,
            reason: '${result[i].name} should follow ${result[i - 1].name}');
      }
    });

    test('appointment dates are date-only, not the minute of birth', () {
      // Birth time was 03:47; nothing should carry that forward, and the old
      // code also added an arbitrary 5 hours to the birth dose.
      for (final MedicalDatesModel m in result) {
        expect(m.date.hour, 0, reason: m.name);
        expect(m.date.minute, 0, reason: m.name);
        expect(m.date.second, 0, reason: m.name);
      }
    });

    test('the birth dose is on the birth day', () {
      expect(result.first.date, DateTime(2026, 6, 15));
    });

    test('doses land on calendar-correct ages', () {
      final Map<String, DateTime> byCode = <String, DateTime>{
        for (final MedicalDatesModel m in result) m.code!: m.date,
      };

      expect(byCode['penta_opv_pcv_1'], DateTime(2026, 8, 15)); // 2 months
      expect(byCode['penta_opv_pcv_2'], DateTime(2026, 10, 15)); // 4 months
      expect(byCode['penta_opv_pcv_3'], DateTime(2026, 12, 15)); // 6 months
      expect(byCode['measles_1'], DateTime(2027, 3, 15)); // 9 months
      // 12 months. The old code used 350 days, landing on 31 May 2027 -
      // about two weeks early.
      expect(byCode['mmr_varicella_pcv_booster'], DateTime(2027, 6, 15));
      expect(byCode['penta_opv_mmr_2_booster'], DateTime(2027, 12, 15)); // 18mo
      expect(byCode['school_entry_boosters'], DateTime(2031, 6, 15)); // 5y
      expect(byCode['hpv'], DateTime(2037, 6, 15)); // 11y
      expect(byCode['td_booster'], DateTime(2041, 6, 15)); // 15y
    });

    test('a 29 February birth date produces valid dates throughout', () {
      final List<MedicalDatesModel> leap = MedicalDatesGenerator.generator(
        '2024-02-29',
        now: DateTime(2026, 6, 15),
      );

      expect(leap.length, 10);
      // 12 months after 29 Feb 2024 is 28 Feb 2025, not 1 March.
      final MedicalDatesModel twelveMonth = leap.firstWhere(
          (MedicalDatesModel m) => m.code == 'mmr_varicella_pcv_booster');
      expect(twelveMonth.date, DateTime(2025, 2, 28));
    });

    test('a 31-day birth date clamps where the target month is shorter', () {
      final List<MedicalDatesModel> endOfMonth =
          MedicalDatesGenerator.generator(
        '2026-03-31',
        now: DateTime(2026, 6, 15),
      );

      // 2 months after 31 March is 31 May; 4 months is 31 July; but 12 months
      // after 31 March 2026 is 31 March 2027 and 18 months is 30 September.
      final Map<String, DateTime> byCode = <String, DateTime>{
        for (final MedicalDatesModel m in endOfMonth) m.code!: m.date,
      };
      expect(byCode['penta_opv_pcv_1'], DateTime(2026, 5, 31));
      expect(byCode['penta_opv_mmr_2_booster'], DateTime(2027, 9, 30));
    });

    test('propagates an invalid birth date', () {
      expect(() => MedicalDatesGenerator.generator('2030-01-01', now: now),
          throwsA(isA<InvalidBirthDateException>()));
    });

    test('a child born today has every dose but the first in the future', () {
      final List<MedicalDatesModel> future =
          result.where((MedicalDatesModel m) => m.date.isAfter(now)).toList();
      expect(future.length, 9);
    });
  });

  group('MedicalDatesModel', () {
    test('round-trips code through toMap', () {
      final MedicalDatesModel m = MedicalDatesGenerator.generator(
        '2026-06-15',
        now: now,
      ).first;
      expect(m.toMap()['code'], 'bcg_hepb_birth');
    });

    test('tolerates a document missing name, description and state', () {
      // Previously this threw while parsing and took out the schedule screen.
      final MedicalDatesModel m = MedicalDatesModel.fromJson(
          <String, dynamic>{'date': '2026-06-15T00:00:00.000'});
      expect(m.name, '');
      expect(m.description, '');
      expect(m.state, '');
      expect(m.date, DateTime(2026, 6, 15));
    });

    test('tolerates a malformed date rather than throwing', () {
      final MedicalDatesModel m =
          MedicalDatesModel.fromJson(<String, dynamic>{'date': 'rubbish'});
      expect(m.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('accepts an ISO string date', () {
      final MedicalDatesModel m = MedicalDatesModel.fromJson(
          <String, dynamic>{'date': '2027-01-02T00:00:00.000'});
      expect(m.date, DateTime(2027, 1, 2));
    });
  });
}
