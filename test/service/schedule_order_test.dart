import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:flutter_test/flutter_test.dart';

MedicalDatesModel dose(String id, DateTime date, {String state = 'Pending'}) =>
    MedicalDatesModel(
        id: id, name: id, description: '', date: date, state: state);

void main() {
  test('the schedule is listed oldest date first, whatever the id order', () {
    // Ids in the order Firestore returns them (random), dates shuffled.
    final List<MedicalDatesModel> fromFirestore = <MedicalDatesModel>[
      dose('a7', DateTime(2037, 1, 11)),
      dose('b2', DateTime(2026, 3, 11)),
      dose('c9', DateTime(2041, 1, 11)),
      dose('d1', DateTime(2026, 1, 11)),
      dose('e5', DateTime(2027, 1, 11)),
    ];
    expect(
      MedicalDatesController.inScheduleOrder(fromFirestore)
          .map((MedicalDatesModel d) => d.id),
      <String>['d1', 'b2', 'e5', 'a7', 'c9'],
    );
  });

  test('ties on the same day keep a stable order by id', () {
    final DateTime day = DateTime(2026, 5, 11);
    expect(
      MedicalDatesController.inScheduleOrder(
              <MedicalDatesModel>[dose('z', day), dose('m', day)])
          .map((MedicalDatesModel d) => d.id),
      <String>['m', 'z'],
    );
  });

  test('sorting never touches a state (no auto-skip by the back door)', () {
    final List<MedicalDatesModel> sorted =
        MedicalDatesController.inScheduleOrder(<MedicalDatesModel>[
      dose('late', DateTime(2030), state: 'Pending'),
      dose('past', DateTime(2020), state: 'Pending'),
      dose('done', DateTime(2025), state: 'Completed'),
    ]);
    expect(sorted.map((MedicalDatesModel d) => d.state),
        <String>['Pending', 'Completed', 'Pending']);
  });

  test('a generated schedule, shuffled, comes back in age order', () {
    final List<MedicalDatesModel> generated =
        MedicalDatesGenerator.generator('2026-01-11');
    final List<MedicalDatesModel> shuffled = (generated.toList()..shuffle())
        .asMap()
        .entries
        .map((MapEntry<int, MedicalDatesModel> e) =>
            e.value.copyWith(id: 'id${9 - e.key}'))
        .toList();
    final List<DateTime> dates =
        MedicalDatesController.inScheduleOrder(shuffled)
            .map((MedicalDatesModel d) => d.date)
            .toList();
    expect(
        dates, generated.map((MedicalDatesModel d) => d.date).toList()..sort());
  });
}
