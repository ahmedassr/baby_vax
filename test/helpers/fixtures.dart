import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';

/// "Today" in every screen test, so countdowns and overdue are stable.
final DateTime fixedNow = DateTime(2027, 3, 10, 12);

/// A generated schedule for a baby born on 15 Jan 2027, with ids, and the
/// first dose (at birth) already given.
List<MedicalDatesModel> sampleSchedule({
  DateTime? birth,
  Map<String, String> states = const <String, String>{
    'bcg_hepb_birth': 'Completed',
  },
}) {
  final List<MedicalDatesModel> doses = MedicalDatesGenerator.generator(
      '2027-01-15',
      now: birth == null ? fixedNow : birth.add(const Duration(days: 1)));
  return <MedicalDatesModel>[
    for (int i = 0; i < doses.length; i++)
      doses[i].copyWith(
        id: 'dose$i',
        state: states[doses[i].code] ?? doses[i].state,
      ),
  ];
}

/// The profile that goes with [sampleSchedule].
UserModel sampleUser({String? sex = 'female'}) => UserModel(
      uid: 'alice',
      email: 'parent@example.com',
      birthday: '2027-01-15',
      name: 'Lina',
      weight: '4.2',
      height: '55',
      headSize: '',
      bloodPercentage: '',
      sex: sex,
    );
