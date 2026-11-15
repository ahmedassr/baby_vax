import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/growth/who_lms_data.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'who_sd_fixture.dart';

void main() {
  final Map<String, (GrowthMetric, String)> tables = {
    'weightForAgeBoys': (GrowthMetric.weight, 'male'),
    'weightForAgeGirls': (GrowthMetric.weight, 'female'),
    'lengthHeightForAgeBoys': (GrowthMetric.height, 'male'),
    'lengthHeightForAgeGirls': (GrowthMetric.height, 'female'),
    'headForAgeBoys': (GrowthMetric.head, 'male'),
    'headForAgeGirls': (GrowthMetric.head, 'female'),
  };

  test('every table has 61 months', () {
    for (final (m, s) in tables.values) {
      expect(GrowthReference.table(m, s), hasLength(61));
    }
  });

  test(
      'LMS reproduces WHO\'s published -2 SD, median and +2 SD, '
      'every month, every table', () {
    tables.forEach((name, spec) {
      final (GrowthMetric metric, String sex) = spec;
      whoSdFixture[name]!.forEach((month, sd) {
        final WhoLms p = GrowthReference.lmsAt(metric, sex, month.toDouble())!;
        // WHO rounds its SD columns to 0.1.
        expect(GrowthReference.valueAt(-2, p), closeTo(sd.$1, 0.051),
            reason: '$name month $month -2SD');
        expect(GrowthReference.valueAt(0, p), closeTo(sd.$2, 0.051),
            reason: '$name month $month median');
        expect(GrowthReference.valueAt(2, p), closeTo(sd.$3, 0.051),
            reason: '$name month $month +2SD');
      });
    });
  });

  test('z-score and value are inverses', () {
    final WhoLms p = weightForAgeBoys[6];
    for (final double z in <double>[-3, -1.2, 0, 0.7, 2.5]) {
      expect(GrowthReference.zScore(GrowthReference.valueAt(z, p), p),
          closeTo(z, 1e-9));
    }
  });

  test('normal CDF at known points', () {
    expect(GrowthReference.percentileFromZ(0), closeTo(50, 1e-6));
    expect(GrowthReference.percentileFromZ(-1.880794), closeTo(3, 0.001));
    expect(GrowthReference.percentileFromZ(1.880794), closeTo(97, 0.001));
    expect(GrowthReference.percentileFromZ(-1.036433), closeTo(15, 0.001));
    expect(GrowthReference.zFromPercentile(85), closeTo(1.036433, 1e-4));
  });

  test('a median baby reads "around the 50th"', () {
    final r = GrowthReference.reading(
        metric: GrowthMetric.weight,
        sex: 'female',
        ageMonths: 0,
        value: weightForAgeGirls[0].m)!;
    expect(r.band, PercentileBand.around);
    expect(r.roundedPercentile, 50);
    expect(r.percentile, closeTo(50, 0.01));
  });

  test('bands at the edges', () {
    final WhoLms p = weightForAgeBoys[12];
    final low = GrowthReference.reading(
        metric: GrowthMetric.weight,
        sex: 'male',
        ageMonths: 12,
        value: GrowthReference.valueAt(-2.5, p))!;
    final high = GrowthReference.reading(
        metric: GrowthMetric.weight,
        sex: 'male',
        ageMonths: 12,
        value: GrowthReference.valueAt(2.5, p))!;
    expect(low.band, PercentileBand.below3);
    expect(high.band, PercentileBand.above97);
  });

  test('interpolates between whole months', () {
    final a = weightForAgeBoys[3].m, b = weightForAgeBoys[4].m;
    expect(GrowthReference.lmsAt(GrowthMetric.weight, 'male', 3.5)!.m,
        closeTo((a + b) / 2, 1e-9));
  });

  test('no reading without a sex, or past 5 years', () {
    expect(
        GrowthReference.reading(
            metric: GrowthMetric.weight, sex: null, ageMonths: 6, value: 7),
        isNull);
    expect(
        GrowthReference.reading(
            metric: GrowthMetric.weight, sex: 'male', ageMonths: 61, value: 20),
        isNull);
  });

  test('age in months uses WHO\'s 30.4375 days', () {
    expect(
        GrowthReference.ageInMonths(
            DateTime(2027, 1, 15), DateTime(2027, 1, 15)),
        0);
    expect(
        GrowthReference.ageInMonths(DateTime(2027, 1, 1), DateTime(2028, 1, 1)),
        closeTo(365 / 30.4375, 1e-9));
  });
}
