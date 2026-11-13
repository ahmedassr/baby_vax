import 'dart:math' as math;

import '../../../modules/growth/model/measurement_model.dart';
import 'who_lms_data.dart';

/// How a measurement compares with the WHO Child Growth Standards, without
/// judging it.
enum PercentileBand {
  /// Below the 3rd percentile curve.
  below3,

  /// Between the 3rd and the 97th: [GrowthReading.roundedPercentile] says
  /// roughly where.
  around,

  /// Above the 97th percentile curve.
  above97,
}

/// One measurement placed on the WHO reference for the baby's age and sex.
class GrowthReading {
  const GrowthReading({
    required this.z,
    required this.percentile,
    required this.band,
    required this.roundedPercentile,
  });

  /// The z-score (standard deviations from the WHO median).
  final double z;

  /// 0-100.
  final double percentile;

  final PercentileBand band;

  /// The percentile rounded to the nearest 5 (and kept within 5-95), for
  /// "around the 50th percentile": anything finer would claim a precision
  /// a home measurement does not have.
  final int roundedPercentile;
}

/// The WHO Child Growth Standards maths: LMS z-scores, percentiles, and the
/// reference curves, for 0-60 months. See `who_lms_data.dart` for the data
/// and docs/THIRD_PARTY.md for its source.
class GrowthReference {
  const GrowthReference._();

  /// WHO counts ages in days and uses 30.4375 days per month.
  static const double daysPerMonth = 30.4375;

  /// The oldest age the standards cover.
  static const double maxMonths = 60;

  /// The percentile curves drawn on the charts.
  static const List<int> curves = <int>[3, 15, 50, 85, 97];

  /// Age in fractional months at [on] for a child born on [birth].
  static double ageInMonths(DateTime birth, DateTime on) {
    final int days = DateTime.utc(on.year, on.month, on.day)
        .difference(DateTime.utc(birth.year, birth.month, birth.day))
        .inDays;
    return days / daysPerMonth;
  }

  /// The month-by-month table for [metric] and [sex] ('female' / 'male'),
  /// or null for any other sex value.
  static List<WhoLms>? table(GrowthMetric metric, String? sex) {
    final bool? girl = switch (sex) {
      'female' => true,
      'male' => false,
      _ => null,
    };
    if (girl == null) return null;
    return switch (metric) {
      GrowthMetric.weight => girl ? weightForAgeGirls : weightForAgeBoys,
      GrowthMetric.height =>
        girl ? lengthHeightForAgeGirls : lengthHeightForAgeBoys,
      GrowthMetric.head => girl ? headForAgeGirls : headForAgeBoys,
    };
  }

  /// L, M and S at [ageMonths], interpolated linearly between whole months.
  /// Null outside 0-60 months or without a usable sex.
  static WhoLms? lmsAt(GrowthMetric metric, String? sex, double ageMonths) {
    final List<WhoLms>? t = table(metric, sex);
    if (t == null || ageMonths < 0 || ageMonths > maxMonths) return null;
    final int lo = ageMonths.floor().clamp(0, t.length - 1);
    final int hi = (lo + 1).clamp(0, t.length - 1);
    final double f = ageMonths - lo;
    if (f == 0 || lo == hi) return t[lo];
    double mix(double a, double b) => a + (b - a) * f;
    return WhoLms(
        mix(t[lo].l, t[hi].l), mix(t[lo].m, t[hi].m), mix(t[lo].s, t[hi].s));
  }

  /// The LMS z-score of [x].
  static double zScore(double x, WhoLms p) {
    if (p.l == 0) return math.log(x / p.m) / p.s;
    return (math.pow(x / p.m, p.l) - 1) / (p.l * p.s);
  }

  /// The measurement at z-score [z]: the inverse of [zScore].
  static double valueAt(double z, WhoLms p) {
    if (p.l == 0) return p.m * math.exp(p.s * z);
    return p.m * math.pow(1 + p.l * p.s * z, 1 / p.l).toDouble();
  }

  /// Percentile (0-100) of a z-score: the standard normal CDF.
  static double percentileFromZ(double z) => 100 * _normalCdf(z);

  /// The z-score of a percentile (0 < [p] < 100): the inverse CDF.
  static double zFromPercentile(double p) {
    // Bisection is plenty: called a handful of times per chart.
    double lo = -8, hi = 8;
    for (int i = 0; i < 80; i++) {
      final double mid = (lo + hi) / 2;
      if (percentileFromZ(mid) < p) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }

  /// [value] of [metric] measured at [ageMonths], for a child of [sex].
  /// Null when the WHO standards do not cover it (over 5 years, no sex).
  static GrowthReading? reading({
    required GrowthMetric metric,
    required String? sex,
    required double ageMonths,
    required double value,
  }) {
    final WhoLms? p = lmsAt(metric, sex, ageMonths);
    if (p == null || value <= 0) return null;
    final double z = zScore(value, p);
    final double pct = percentileFromZ(z);
    final PercentileBand band = pct < 3
        ? PercentileBand.below3
        : pct > 97
            ? PercentileBand.above97
            : PercentileBand.around;
    final int rounded = ((pct / 5).round() * 5).clamp(5, 95);
    return GrowthReading(
        z: z, percentile: pct, band: band, roundedPercentile: rounded);
  }

  /// Standard normal CDF via the error function (Abramowitz & Stegun
  /// 7.1.26; absolute error below 1.5e-7).
  static double _normalCdf(double z) => 0.5 * (1 + _erf(z / math.sqrt2));

  static double _erf(double x) {
    final double sign = x < 0 ? -1 : 1;
    final double a = x.abs();
    const double p = 0.3275911;
    const List<double> c = <double>[
      0.254829592,
      -0.284496736,
      1.421413741,
      -1.453152027,
      1.061405429
    ];
    final double t = 1 / (1 + p * a);
    double poly = 0;
    for (int i = c.length - 1; i >= 0; i--) {
      poly = poly * t + c[i];
    }
    return sign * (1 - poly * t * math.exp(-a * a));
  }
}
