import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime at = DateTime(2027, 3, 10, 9, 20);

  /// The fields firestore.rules allows on a health_log document.
  const Set<String> ruleFields = <String>{
    'kind', 'at', 'tempC', 'method', 'symptoms', 'medicine', 'amount', //
    'note', 'doseId',
  };

  final List<HealthEntry> samples = <HealthEntry>[
    HealthEntry(
        kind: HealthEntryKind.temperature,
        at: at,
        tempC: 38.4,
        method: TemperatureMethod.armpit,
        note: 'after the bath'),
    HealthEntry(
        kind: HealthEntryKind.symptoms,
        at: at,
        symptoms: const <HealthSymptom>[
          HealthSymptom.feelsHot,
          HealthSymptom.injectionSite
        ],
        doseId: 'd1'),
    HealthEntry(
        kind: HealthEntryKind.medicine,
        at: at,
        medicine: ' Paracetamol ',
        amount: '2.5 ml'),
    HealthEntry(kind: HealthEntryKind.note, at: at, note: 'Slept well'),
  ];

  for (final HealthEntry e in samples) {
    test('${e.kind.name}: round-trips and writes only allowed fields', () {
      final Map<String, dynamic> m = e.toMap();
      expect(ruleFields.containsAll(m.keys), isTrue, reason: '${m.keys}');
      final HealthEntry back = HealthEntry.fromJson('x', m);
      expect(back.kind, e.kind);
      expect(back.at, at);
      expect(back.tempC, e.tempC);
      expect(back.method, e.method);
      expect(back.symptoms, e.symptoms);
      expect(back.medicine, e.medicine?.trim());
      expect(back.amount, e.amount);
      expect(back.note, e.note);
      expect(back.doseId, e.doseId);
      expect(e.isComplete, isTrue);
    });
  }

  test('symptoms are stored by the names the rules list', () {
    expect(
        samples[1].toMap()['symptoms'], <String>['feelsHot', 'injectionSite']);
  });

  test('incomplete entries are recognised', () {
    expect(
        HealthEntry(kind: HealthEntryKind.temperature, at: at, tempC: 98.6)
            .isComplete,
        isFalse,
        reason: 'a reading in °F');
    expect(HealthEntry(kind: HealthEntryKind.symptoms, at: at).isComplete,
        isFalse);
    expect(
        HealthEntry(kind: HealthEntryKind.medicine, at: at, medicine: '  ')
            .isComplete,
        isFalse);
    expect(HealthEntry(kind: HealthEntryKind.note, at: at).isComplete, isFalse);
  });

  test('a damaged document still reads', () {
    final HealthEntry e = HealthEntry.fromJson('x', <String, dynamic>{
      'kind': 'diaper',
      'tempC': 'hot',
      'symptoms': <Object?>['feelsHot', 'sneezing', null],
    });
    expect(e.kind, HealthEntryKind.note);
    expect(e.tempC, isNull);
    expect(e.symptoms, <HealthSymptom>[HealthSymptom.feelsHot]);
  });

  test('newest first', () {
    final List<HealthEntry> sorted = HealthEntry.newestFirst(<HealthEntry>[
      HealthEntry(id: 'a', kind: HealthEntryKind.note, at: at, note: 'x'),
      HealthEntry(
          id: 'b',
          kind: HealthEntryKind.note,
          at: at.add(const Duration(hours: 1)),
          note: 'y'),
    ]);
    expect(sorted.map((e) => e.id), <String>['b', 'a']);
  });

  group('UserModel health profile', () {
    test('reads, writes only what is set, and keeps v1.0 profiles valid', () {
      final UserModel u = UserModel.fromJson(<String, dynamic>{
        'uid': 'u',
        'email': 'p@example.com',
        'allergies': ' Penicillin ',
        'bloodType': 'O+',
      });
      expect(u.allergies, 'Penicillin');
      expect(u.bloodType, 'O+');
      expect(u.conditions, isNull);
      expect(u.hasHealthProfile, isTrue);
      final Map<String, dynamic> m = u.toMap();
      expect(m['allergies'], 'Penicillin');
      expect(m.containsKey('conditions'), isFalse);
      expect(m.containsKey('emergencyContact'), isFalse);

      final UserModel v10 = UserModel.fromJson(
          <String, dynamic>{'uid': 'u', 'email': 'p@example.com'});
      expect(v10.hasHealthProfile, isFalse);
      for (final String f in UserModel.healthFields) {
        expect(v10.toMap().containsKey(f), isFalse);
      }
    });

    test('an unknown blood type is ignored', () {
      expect(UserModel.fromJson(<String, dynamic>{'bloodType': 'O'}).bloodType,
          isNull);
    });
  });

  test('account deletion walks the health log too', () {
    expect(AppPath.userSubcollections('u'), contains('users/u/health_log'));
  });
}
