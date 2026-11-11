import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeWriter implements DoseStateWriter {
  final List<(String, MedicalDateStateEnum)> writes = [];
  final List<DoseRecord?> records = [];
  final List<bool> clears = [];
  final List<(String, DoseRecord)> recordWrites = [];
  Object? failWith;

  WriteOutcome outcome = WriteOutcome.synced;

  @override
  Future<WriteOutcome> writeState(
    String doseId,
    MedicalDateStateEnum state, {
    DoseRecord? record,
    bool clearRecord = false,
  }) async {
    if (failWith != null) throw failWith!;
    writes.add((doseId, state));
    records.add(record);
    clears.add(clearRecord);
    return outcome;
  }

  @override
  Future<WriteOutcome> writeRecord(String doseId, DoseRecord record) async {
    if (failWith != null) throw failWith!;
    recordWrites.add((doseId, record));
    return outcome;
  }
}

class FakeReminders implements DoseReminders {
  final List<String> cancelled = [];
  final List<MedicalDatesModel> scheduled = [];

  @override
  Future<void> cancel(String doseId) async => cancelled.add(doseId);

  @override
  Future<void> schedule(MedicalDatesModel dose) async => scheduled.add(dose);
}

void main() {
  // Midday, so "same day" checks can't pass by accident at midnight.
  final DateTime now = DateTime(2026, 6, 15, 12);

  MedicalDatesModel dose({
    String state = 'Pending',
    DateTime? date,
    String? id = 'dose_1',
  }) =>
      MedicalDatesModel(
        id: id,
        code: 'hpv',
        name: 'HPV',
        description: 'desc',
        date: date ?? now,
        state: state,
      );

  group('VaccineStatePolicy', () {
    test('overdue means Pending with a day before today', () {
      final yesterday = DateTime(2026, 6, 14, 23, 59);
      expect(VaccineStatePolicy.isOverdue(dose(date: yesterday), now), isTrue);
      expect(
          VaccineStatePolicy.isOverdue(
              dose(date: yesterday, state: 'Completed'), now),
          isFalse);
      expect(
          VaccineStatePolicy.isOverdue(
              dose(date: yesterday, state: 'Skipped'), now),
          isFalse);
    });

    test('a dose due today is neither overdue nor in the future', () {
      final todayMidnight = DateTime(2026, 6, 15);
      final todayLate = DateTime(2026, 6, 15, 23, 59);
      for (final d in [todayMidnight, todayLate]) {
        expect(VaccineStatePolicy.isOverdue(dose(date: d), now), isFalse);
        expect(VaccineStatePolicy.isInFuture(dose(date: d), now), isFalse);
      }
    });

    test('Mark Completed is allowed on any Pending dose, past or future', () {
      for (final d in [
        DateTime(2025, 1, 1),
        now,
        DateTime(2027, 1, 1),
      ]) {
        expect(VaccineStatePolicy.canMarkCompleted(dose(date: d)), isTrue);
        expect(VaccineStatePolicy.canMarkSkipped(dose(date: d)), isTrue);
        expect(VaccineStatePolicy.canUndo(dose(date: d)), isFalse);
      }
    });

    test('Completed and Skipped can only be undone', () {
      for (final s in ['Completed', 'Skipped']) {
        expect(VaccineStatePolicy.canMarkCompleted(dose(state: s)), isFalse);
        expect(VaccineStatePolicy.canMarkSkipped(dose(state: s)), isFalse);
        expect(VaccineStatePolicy.canUndo(dose(state: s)), isTrue);
      }
    });

    test('only a future dose needs confirmation before Mark Completed', () {
      expect(
          VaccineStatePolicy.completionNeedsConfirmation(
              dose(date: DateTime(2026, 6, 16)), now),
          isTrue);
      expect(
          VaccineStatePolicy.completionNeedsConfirmation(dose(), now), isFalse);
      expect(
          VaccineStatePolicy.completionNeedsConfirmation(
              dose(date: DateTime(2026, 6, 1)), now),
          isFalse);
      expect(
          VaccineStatePolicy.completionNeedsConfirmation(
              dose(date: DateTime(2026, 6, 16), state: 'Completed'), now),
          isFalse);
    });

    test('an unknown stored state reads as Pending, never Skipped', () {
      expect(
          MedicalDateStateEnum.fromLabel(null), MedicalDateStateEnum.pending);
      expect(MedicalDateStateEnum.fromLabel('garbage'),
          MedicalDateStateEnum.pending);
      expect(MedicalDateStateEnum.fromLabel('skipped'),
          MedicalDateStateEnum.skipped);
    });
  });

  group('VaccineStateService', () {
    late FakeWriter writer;
    late FakeReminders reminders;
    late VaccineStateService service;

    setUp(() {
      writer = FakeWriter();
      reminders = FakeReminders();
      service = VaccineStateService(writer: writer, reminders: reminders);
    });

    test('markCompleted writes Completed and cancels the reminders', () async {
      final result = (await service.markCompleted(dose())).dose;
      expect(result.state, 'Completed');
      expect(writer.writes, [('dose_1', MedicalDateStateEnum.completed)]);
      expect(reminders.cancelled, ['dose_1']);
      expect(reminders.scheduled, isEmpty);
    });

    test('markCompleted works on a future Pending dose', () async {
      final result =
          (await service.markCompleted(dose(date: DateTime(2027, 3, 1)))).dose;
      expect(result.state, 'Completed');
    });

    test('markSkipped writes Skipped and cancels the reminders', () async {
      final result = (await service.markSkipped(dose())).dose;
      expect(result.state, 'Skipped');
      expect(writer.writes, [('dose_1', MedicalDateStateEnum.skipped)]);
      expect(reminders.cancelled, ['dose_1']);
    });

    for (final from in ['Completed', 'Skipped']) {
      test('undo from $from writes Pending and reschedules', () async {
        final result = (await service.undo(dose(state: from))).dose;
        expect(result.state, 'Pending');
        expect(writer.writes, [('dose_1', MedicalDateStateEnum.pending)]);
        expect(reminders.cancelled, isEmpty);
        expect(reminders.scheduled.single.id, 'dose_1');
        expect(reminders.scheduled.single.state, 'Pending');
      });
    }

    test('the result keeps every other field', () async {
      final original = dose(date: DateTime(2027, 3, 1));
      final result = (await service.markSkipped(original)).dose;
      expect(result.id, original.id);
      expect(result.code, original.code);
      expect(result.name, original.name);
      expect(result.description, original.description);
      expect(result.date, original.date);
    });

    test('disallowed transitions throw and change nothing', () async {
      await expectLater(service.markCompleted(dose(state: 'Completed')),
          throwsA(isA<InvalidStateTransition>()));
      await expectLater(service.markSkipped(dose(state: 'Skipped')),
          throwsA(isA<InvalidStateTransition>()));
      await expectLater(service.markCompleted(dose(state: 'Skipped')),
          throwsA(isA<InvalidStateTransition>()));
      await expectLater(
          service.undo(dose()), throwsA(isA<InvalidStateTransition>()));
      expect(writer.writes, isEmpty);
      expect(reminders.cancelled, isEmpty);
      expect(reminders.scheduled, isEmpty);
    });

    test('an unsaved dose is rejected', () async {
      await expectLater(
          service.markCompleted(dose(id: null)), throwsArgumentError);
      await expectLater(
          service.markCompleted(dose(id: '')), throwsArgumentError);
      expect(writer.writes, isEmpty);
    });

    test('reports a change saved offline, and still updates reminders',
        () async {
      writer.outcome = WriteOutcome.pendingSync;
      final change = await service.markCompleted(dose());
      expect(change.outcome, WriteOutcome.pendingSync);
      expect(change.dose.state, 'Completed');
      expect(reminders.cancelled, ['dose_1']);
    });

    test('a failed write leaves the reminders alone', () async {
      writer.failWith = Exception('denied');
      await expectLater(service.markCompleted(dose()), throwsException);
      expect(reminders.cancelled, isEmpty);
      expect(reminders.scheduled, isEmpty);
    });
  });

  group('remainingTimeFrom', () {
    VaccinationTimeStatusEnum status(DateTime d) =>
        d.remainingTimeFrom(now).status;

    test('counts calendar days, not hours', () {
      expect(status(DateTime(2026, 6, 15)), VaccinationTimeStatusEnum.today);
      expect(status(DateTime(2026, 6, 15, 23, 59)),
          VaccinationTimeStatusEnum.today);
      expect(status(DateTime(2026, 6, 14, 23, 59)),
          VaccinationTimeStatusEnum.overdue);
      expect(status(DateTime(2026, 6, 16)), VaccinationTimeStatusEnum.tomorrow);
    });

    test('days, weeks, months, years', () {
      final r3 = DateTime(2026, 6, 18).remainingTimeFrom(now);
      expect((r3.status, r3.value), (VaccinationTimeStatusEnum.daysLeft, 3));
      final r2w = DateTime(2026, 6, 29).remainingTimeFrom(now);
      expect((r2w.status, r2w.value), (VaccinationTimeStatusEnum.weeksLeft, 2));
      final r3m = DateTime(2026, 9, 15).remainingTimeFrom(now);
      expect(
          (r3m.status, r3m.value), (VaccinationTimeStatusEnum.monthsLeft, 3));
      final r2y = DateTime(2028, 7, 1).remainingTimeFrom(now);
      expect((r2y.status, r2y.value), (VaccinationTimeStatusEnum.yearsLeft, 2));
    });
  });
}
