import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMap writes only measured values, date-only, in the rules\' names',
      () {
    final m = MeasurementModel(
        date: DateTime(2027, 3, 10, 15, 30), weightKg: 4.2, note: '  ');
    final map = m.toMap();
    expect(map.keys.toSet(), <String>{'date', 'weightKg'});
    expect((map['date'] as Timestamp).toDate(), DateTime(2027, 3, 10));
    for (final k in map.keys.where((k) => k != 'date')) {
      expect(GrowthMetric.values.map((g) => g.field), contains(k));
    }
  });

  test('fromMap tolerates integers and missing fields', () {
    final m = MeasurementModel.fromMap(<String, dynamic>{
      'date': Timestamp.fromDate(DateTime(2027, 3, 10)),
      'heightCm': 55,
    }, 'm1');
    expect(m.heightCm, 55.0);
    expect(m.weightKg, isNull);
    expect(m.id, 'm1');
  });

  test('latestForProfile takes the newest value of each metric', () {
    final all = <MeasurementModel>[
      MeasurementModel(
          id: 'a', date: DateTime(2027, 1, 15), weightKg: 3.4, heightCm: 50),
      MeasurementModel(id: 'b', date: DateTime(2027, 3, 10), weightKg: 5),
      MeasurementModel(id: 'c', date: DateTime(2027, 2, 15), headCm: 37.5),
    ];
    final latest = MeasurementModel.latestForProfile(all);
    expect(latest[GrowthMetric.weight], '5');
    expect(latest[GrowthMetric.height], '50');
    expect(latest[GrowthMetric.head], '37.5');
    expect(
        MeasurementModel.latestForProfile(const <MeasurementModel>[])
            .values
            .every((v) => v == null),
        isTrue);
  });

  test('bounds match the rules', () {
    expect(GrowthMetric.weight.bounds, (min: 0.3, max: 150));
    expect(GrowthMetric.height.bounds, (min: 20, max: 220));
    expect(GrowthMetric.head.bounds, (min: 20, max: 70));
  });

  test('account deletion walks the measurements collection too', () {
    expect(AppPath.userSubcollections('u'),
        containsAll(<String>['users/u/medical_dates', 'users/u/measurements']));
  });
}
