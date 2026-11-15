import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vaccine_state_service_test.dart' show FakeReminders, FakeWriter;

void main() {
  MedicalDatesModel dose({String state = 'Pending', DoseRecord? record}) =>
      MedicalDatesModel(
        id: 'd1',
        code: 'measles_1',
        name: 'Measles',
        description: '',
        date: DateTime(2027, 10, 15),
        state: state,
        record: record ?? const DoseRecord(),
      );

  final DoseRecord full = DoseRecord(
    givenDate: DateTime(2027, 10, 16, 14, 30),
    clinic: '  Ramallah MCH  ',
    lot: 'AB1234',
    note: '',
  );

  group('DoseRecord', () {
    test('normalises: trims, drops blanks, date-only', () {
      final r = full.normalised();
      expect(r.clinic, 'Ramallah MCH');
      expect(r.note, isNull);
      expect(r.givenDate, DateTime(2027, 10, 16));
    });

    test('toMap writes only filled fields, in the rules\' names', () {
      final m = full.toMap();
      expect(m.keys.toSet(), <String>{'givenDate', 'clinic', 'lot'});
      expect(m['givenDate'], isA<Timestamp>());
      expect(DoseRecord.fields.toSet().containsAll(m.keys), isTrue);
    });

    test('empty when nothing is filled', () {
      expect(const DoseRecord(clinic: '  ').isEmpty, isTrue);
      expect(full.isEmpty, isFalse);
    });
  });

  group('MedicalDatesModel', () {
    test('round-trips the record through toMap / fromJson', () {
      final m = dose(state: 'Completed', record: full.normalised()).toMap();
      final back = MedicalDatesModel.fromJson(m);
      expect(back.record.clinic, 'Ramallah MCH');
      expect(back.record.lot, 'AB1234');
      expect(back.record.givenDate, DateTime(2027, 10, 16));
    });

    test('a v1.0 document has an empty record', () {
      final back = MedicalDatesModel.fromJson(<String, dynamic>{
        'name': 'x',
        'date': Timestamp.fromDate(DateTime(2027)),
        'state': 'Completed',
      });
      expect(back.record.isEmpty, isTrue);
    });

    test('toMap keeps the record, so full rewrites do not drop it', () {
      expect(dose(state: 'Completed', record: full).toMap(),
          containsPair('lot', 'AB1234'));
    });
  });

  group('VaccineStateService with a record', () {
    late FakeWriter writer;
    late VaccineStateService service;

    setUp(() {
      writer = FakeWriter();
      service = VaccineStateService(writer: writer, reminders: FakeReminders());
    });

    test('mark given writes the record with the state', () async {
      final change = await service.markCompleted(dose(), record: full);
      expect(writer.records.single!.clinic, 'Ramallah MCH');
      expect(change.dose.record.lot, 'AB1234');
    });

    test('mark given with an empty record writes state only, as v1.0',
        () async {
      await service.markCompleted(dose());
      expect(writer.records.single, isNull);
      expect(writer.clears.single, isFalse);
    });

    test('undo clears the record', () async {
      final change = await service
          .undo(dose(state: 'Completed', record: full.normalised()));
      expect(writer.clears.single, isTrue);
      expect(change.dose.record.isEmpty, isTrue);
    });

    test('skip never writes a record', () async {
      await service.markSkipped(dose());
      expect(writer.records.single, isNull);
    });

    test('updateRecord edits a given dose and refuses any other', () async {
      final change = await service.updateRecord(
          dose(state: 'Completed'), const DoseRecord(lot: ' XY9 '));
      expect(writer.recordWrites.single.$2.lot, 'XY9');
      expect(change.dose.record.lot, 'XY9');
      expect(() => service.updateRecord(dose(), full),
          throwsA(isA<InvalidStateTransition>()));
    });
  });
}
