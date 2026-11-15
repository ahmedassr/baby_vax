import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/growth/who_lms_data.dart';

import '../model/measurement_model.dart';

/// One point on the chart: age in months and the measured value.
typedef GrowthPoint = ({double age, double value});

/// The baby's measurements over age, on the WHO percentile curves when they
/// apply.
///
/// Drawn with a [CustomPainter] rather than a chart package: no download
/// cost, and full control over the axes, which run right to left in Arabic.
/// The 50th percentile is the strongest line; 15th/85th and 3rd/97th are
/// progressively fainter, so the band reads as "the usual range" without any
/// colour implying good or bad.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.metric,
    required this.points,
    required this.sex,
    required this.unit,
    required this.semanticLabel,
    this.ageNow,
  });

  final GrowthMetric metric;
  final List<GrowthPoint> points;

  /// 'female' / 'male', or null: no curves.
  final String? sex;

  /// "kg" or "cm", for the axis.
  final String unit;
  final String semanticLabel;

  /// Today's age in months, so the x axis reaches it even with old points.
  final double? ageNow;

  /// The x range: from 0 to a little past the oldest of [points] and
  /// [ageNow], at least 6 months, at most 60 when curves are drawn.
  static (double, double) xRange(List<GrowthPoint> points, double? ageNow) {
    double hi = math.max(6, ageNow ?? 0);
    for (final GrowthPoint p in points) {
      hi = math.max(hi, p.age);
    }
    hi = (hi + 1).ceilToDouble();
    return (0, hi);
  }

  /// The WHO curves, sampled every half month across [x].
  static Map<int, List<GrowthPoint>> curves(
      GrowthMetric metric, String? sex, (double, double) x) {
    final Map<int, List<GrowthPoint>> out = <int, List<GrowthPoint>>{};
    if (GrowthReference.table(metric, sex) == null) return out;
    for (final int p in GrowthReference.curves) {
      final double z = GrowthReference.zFromPercentile(p.toDouble());
      final List<GrowthPoint> line = <GrowthPoint>[];
      for (double a = x.$1;
          a <= math.min(x.$2, GrowthReference.maxMonths);
          a += 0.5) {
        final WhoLms? lms = GrowthReference.lmsAt(metric, sex, a);
        if (lms != null) {
          line.add((age: a, value: GrowthReference.valueAt(z, lms)));
        }
      }
      out[p] = line;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (double, double) x = xRange(points, ageNow);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: CustomPaint(
          painter: _GrowthPainter(
            points: points,
            curves: curves(metric, sex, x),
            x: x,
            rtl: Directionality.of(context) == TextDirection.rtl,
            unit: unit,
            monthsLabel: "Growth_axis_months".tr,
            ink: theme.colorScheme.onSurfaceVariant,
            grid: theme.colorScheme.outlineVariant,
            curve: theme.colorScheme.tertiary,
            point: theme.colorScheme.primary,
            pointFill: theme.colorScheme.surface,
            labelStyle: theme.textTheme.labelSmall!,
          ),
        ),
      ),
    );
  }
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter({
    required this.points,
    required this.curves,
    required this.x,
    required this.rtl,
    required this.unit,
    required this.monthsLabel,
    required this.ink,
    required this.grid,
    required this.curve,
    required this.point,
    required this.pointFill,
    required this.labelStyle,
  });

  final List<GrowthPoint> points;
  final Map<int, List<GrowthPoint>> curves;
  final (double, double) x;
  final bool rtl;
  final String unit;
  final String monthsLabel;
  final Color ink;
  final Color grid;
  final Color curve;
  final Color point;
  final Color pointFill;
  final TextStyle labelStyle;

  /// Gutters: y labels at the start, percentile labels at the end.
  static const double _left = 40, _bottom = 44, _top = 26, _right = 28;

  @override
  void paint(Canvas canvas, Size size) {
    // y range from everything drawn, padded.
    final Iterable<double> ys = <double>[
      for (final List<GrowthPoint> l in curves.values) ...l.map((p) => p.value),
      ...points.map((p) => p.value),
    ];
    if (ys.isEmpty) return;
    double yLo = ys.reduce(math.min), yHi = ys.reduce(math.max);
    final double pad = math.max((yHi - yLo) * 0.08, 0.5);
    yLo = math.max(0, yLo - pad);
    yHi = yHi + pad;

    final Rect plot = Rect.fromLTRB(
      rtl ? _right : _left,
      _top,
      size.width - (rtl ? _left : _right),
      size.height - _bottom,
    );
    Offset at(double age, double v) {
      final double fx = (age - x.$1) / (x.$2 - x.$1);
      final double fy = (v - yLo) / (yHi - yLo);
      final double px =
          rtl ? plot.right - fx * plot.width : plot.left + fx * plot.width;
      return Offset(px, plot.bottom - fy * plot.height);
    }

    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    // Horizontal grid and y labels: about five steps.
    final double yStep = _niceStep((yHi - yLo) / 5);
    for (double v = (yLo / yStep).ceil() * yStep; v <= yHi; v += yStep) {
      final Offset p = at(x.$1, v);
      canvas.drawLine(
          Offset(plot.left, p.dy), Offset(plot.right, p.dy), gridPaint);
      _label(canvas, _fmt(v), Offset(rtl ? plot.right + 4 : 4, p.dy - 7));
    }
    // x labels.
    final double span = x.$2 - x.$1;
    final double xStep =
        span <= 12 ? 2 : (span <= 24 ? 3 : (span <= 36 ? 6 : 12));
    for (double a = x.$1; a <= x.$2; a += xStep) {
      final Offset p = at(a, yLo);
      canvas.drawLine(
          Offset(p.dx, plot.bottom), Offset(p.dx, plot.bottom + 4), gridPaint);
      _label(canvas, _fmt(a), Offset(p.dx - 8, plot.bottom + 6));
    }
    _label(canvas, monthsLabel,
        Offset(rtl ? plot.left : plot.right - 80, size.height - 14));
    _label(canvas, unit, Offset(rtl ? plot.right + 4 : 4, 0));

    // WHO curves.
    curves.forEach((int pct, List<GrowthPoint> line) {
      if (line.length < 2) return;
      final double alpha =
          pct == 50 ? 0.9 : (pct == 15 || pct == 85 ? 0.55 : 0.35);
      final Paint p = Paint()
        ..color = curve.withValues(alpha: alpha)
        ..strokeWidth = pct == 50 ? 2 : 1.25
        ..style = PaintingStyle.stroke;
      final Path path = Path()
        ..moveTo(at(line.first.age, line.first.value).dx,
            at(line.first.age, line.first.value).dy);
      for (final GrowthPoint q in line.skip(1)) {
        final Offset o = at(q.age, q.value);
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
      final Offset end = at(line.last.age, line.last.value);
      _label(canvas, '$pct', Offset(rtl ? end.dx - 22 : end.dx + 4, end.dy - 7),
          color: curve);
    });

    // The baby's measurements.
    final Paint linePaint = Paint()
      ..color = point
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < points.length; i++) {
      canvas.drawLine(at(points[i - 1].age, points[i - 1].value),
          at(points[i].age, points[i].value), linePaint);
    }
    for (final GrowthPoint q in points) {
      final Offset o = at(q.age, q.value);
      canvas.drawCircle(o, 5, Paint()..color = pointFill);
      canvas.drawCircle(o, 5, linePaint);
    }
  }

  void _label(Canvas canvas, String text, Offset at, {Color? color}) {
    final TextPainter tp = TextPainter(
      text:
          TextSpan(text: text, style: labelStyle.copyWith(color: color ?? ink)),
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final double mag =
        math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final double m in <double>[1, 2, 2.5, 5, 10]) {
      if (raw <= m * mag) return m * mag;
    }
    return 10 * mag;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(_GrowthPainter old) =>
      old.points != points ||
      old.curves != curves ||
      old.rtl != rtl ||
      old.ink != ink;
}
