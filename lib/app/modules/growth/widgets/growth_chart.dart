import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/growth/who_lms_data.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';

import '../model/measurement_model.dart';

/// One point on the chart: age in months, the measured value and, when
/// known, the day it was measured (shown when the point is tapped).
class GrowthPoint {
  const GrowthPoint({required this.age, required this.value, this.date});

  final double age;
  final double value;
  final DateTime? date;
}

/// The WHO reference drawn behind the baby's points: the 3rd and 97th
/// percentiles (the shaded band) and the median (the "Average" line),
/// sampled every half month.
class GrowthBand {
  const GrowthBand(
      {required this.lower, required this.median, required this.upper});

  final List<GrowthPoint> lower;
  final List<GrowthPoint> median;
  final List<GrowthPoint> upper;

  bool get isEmpty => median.length < 2;
}

/// The axes of one chart: the ages shown and the values shown.
///
/// The value axis is fitted to the WHO band for the ages shown, so one
/// mistyped value (33 kg at birth) cannot squash the curves into a line.
/// A point outside it is drawn at the edge with a marker instead.
class GrowthScale {
  const GrowthScale({
    required this.xLo,
    required this.xHi,
    required this.yLo,
    required this.yHi,
    required this.band,
  });

  final double xLo, xHi, yLo, yHi;
  final GrowthBand? band;

  /// Whether [v] lies outside the value axis (drawn at the edge).
  bool isOutside(double v) => v < yLo || v > yHi;

  /// [v] held to the value axis.
  double clampY(double v) => v.clamp(yLo, yHi).toDouble();

  /// The ages: from 0 to a little past the oldest of [points] and [ageNow],
  /// at least 6 months.
  static (double, double) xRange(List<GrowthPoint> points, double? ageNow) {
    double hi = math.max(6, ageNow ?? 0);
    for (final GrowthPoint p in points) {
      hi = math.max(hi, p.age);
    }
    return (0, (hi + 1).ceilToDouble());
  }

  /// The WHO curve at percentile [pct] for [sex] across [xLo]..[xHi], every
  /// half month, stopping at 5 years.
  static List<GrowthPoint> curve(
      GrowthMetric metric, String? sex, double pct, double xLo, double xHi) {
    final double z = GrowthReference.zFromPercentile(pct);
    final List<GrowthPoint> line = <GrowthPoint>[];
    final double end = math.min(xHi, GrowthReference.maxMonths);
    for (double a = xLo; a <= end + 1e-9; a += 0.5) {
      final WhoLms? lms = GrowthReference.lmsAt(metric, sex, a);
      if (lms != null) {
        line.add(GrowthPoint(age: a, value: GrowthReference.valueAt(z, lms)));
      }
    }
    return line;
  }

  /// The scale for [points] of [metric]. [sex] null: no band is drawn, and
  /// the limits for "outside the chart" are those of both sexes together.
  static GrowthScale of({
    required GrowthMetric metric,
    required String? sex,
    required List<GrowthPoint> points,
    double? ageNow,
  }) {
    final (double xLo, double xHi) = xRange(points, ageNow);
    GrowthBand? band;
    if (GrowthReference.table(metric, sex) != null) {
      band = GrowthBand(
        lower: curve(metric, sex, GrowthReference.bandLowPercentile, xLo, xHi),
        median: curve(metric, sex, 50, xLo, xHi),
        upper: curve(metric, sex, GrowthReference.bandHighPercentile, xLo, xHi),
      );
      if (band.isEmpty) band = null;
    }

    // The widest values a point may have and still be drawn where it is:
    // the 0.1st and 99.9th percentiles (both sexes when the sex is unknown).
    double? limLo, limHi;
    for (final String s in switch (sex) {
      'female' || 'male' => <String>[sex!],
      _ => <String>['female', 'male'],
    }) {
      final List<GrowthPoint> lo =
          curve(metric, s, GrowthReference.unusualLowPercentile, xLo, xHi);
      final List<GrowthPoint> hi =
          curve(metric, s, GrowthReference.unusualHighPercentile, xLo, xHi);
      if (lo.isEmpty || hi.isEmpty) continue;
      final double l = lo.map((GrowthPoint p) => p.value).reduce(math.min);
      final double h = hi.map((GrowthPoint p) => p.value).reduce(math.max);
      limLo = limLo == null ? l : math.min(limLo, l);
      limHi = limHi == null ? h : math.max(limHi, h);
    }

    double? lo, hi;
    void take(double v) {
      lo = lo == null ? v : math.min(lo!, v);
      hi = hi == null ? v : math.max(hi!, v);
    }

    if (band != null) {
      for (final GrowthPoint p in <GrowthPoint>[...band.lower, ...band.upper]) {
        take(p.value);
      }
    }
    for (final GrowthPoint p in points) {
      // Only points over 5 years have no limits; they always fit.
      final bool inside = limLo == null ||
          limHi == null ||
          p.age > GrowthReference.maxMonths ||
          (p.value >= limLo && p.value <= limHi);
      if (inside) take(p.value);
    }
    if (lo == null || hi == null) {
      // Every point is far out and there is no band: show the limits.
      lo = limLo ?? 0;
      hi = limHi ?? 1;
    }
    final double pad = math.max((hi! - lo!) * 0.06, 0.2);
    return GrowthScale(
      xLo: xLo,
      xHi: xHi,
      yLo: math.max(0, lo! - pad),
      yHi: hi! + pad,
      band: band,
    );
  }
}

/// The baby's measurements over age, on the WHO band when it applies.
///
/// Built for parents rather than clinicians: a shaded band where most
/// babies of the same age and sex are (3rd-97th percentile), one "Average"
/// line (the median), the baby's points joined by a line, titled axes with
/// units, and a tap on a point to read it in plain words. Age always runs
/// left to right, in Arabic too, as on printed growth charts.
///
/// Drawn with a [CustomPainter] rather than a chart package: no download
/// cost, and full control over the axes.
class GrowthChart extends StatefulWidget {
  const GrowthChart({
    super.key,
    required this.metric,
    required this.points,
    required this.sex,
    required this.unit,
    required this.metricLabel,
    required this.semanticLabel,
    this.ageNow,
    this.compact = false,
  });

  final GrowthMetric metric;

  /// Oldest first.
  final List<GrowthPoint> points;

  /// 'female' / 'male', or null: no band.
  final String? sex;

  /// "kg" or "cm".
  final String unit;

  /// "Weight", for the value axis title.
  final String metricLabel;
  final String semanticLabel;

  /// Today's age in months, so the age axis reaches it even with old points.
  final double? ageNow;

  /// The small version on Home: shorter, fewer ticks, no tap details (the
  /// whole card opens the growth screen).
  final bool compact;

  /// "around average" for [value] of [metric] at [age], or null when the
  /// WHO standards cannot place it.
  static String? positionText(
      GrowthMetric metric, String? sex, double age, double value) {
    final GrowthReading? r = GrowthReference.reading(
        metric: metric, sex: sex, ageMonths: age, value: value);
    if (r == null) return null;
    return 'Growth_position_${GrowthPosition.of(r.percentile).name}'.tr;
  }

  static String formatValue(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  State<GrowthChart> createState() => GrowthChartState();
}

/// Public so tests can find where each point was drawn.
class GrowthChartState extends State<GrowthChart> {
  int? _selected;
  _Geometry? _geometry;

  /// Where each of the widget's points was last drawn, in the chart's own
  /// coordinates.
  @visibleForTesting
  List<Offset> get pointOffsets => <Offset>[
        if (_geometry != null)
          for (final GrowthPoint p in widget.points) _geometry!.of(p),
      ];

  /// The value axis last drawn.
  @visibleForTesting
  GrowthScale? get scale => _geometry?.scale;

  @override
  void didUpdateWidget(GrowthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric ||
        oldWidget.points.length != widget.points.length) {
      _selected = null;
    }
  }

  _ChartStyle _style(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppChartColors chart = AppChartColors.of(context);
    return _ChartStyle(
      ink: chart.ink,
      grid: chart.grid,
      band: chart.referenceBand,
      bandEdge: chart.reference.withValues(alpha: 0.35),
      average: chart.reference,
      point: chart.series,
      pointFill: scheme.surface,
      outside: chart.alert,
      label:
          theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
      title: theme.textTheme.labelMedium!.copyWith(color: scheme.onSurface),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GrowthScale scale = GrowthScale.of(
        metric: widget.metric,
        sex: widget.sex,
        points: widget.points,
        ageNow: widget.ageNow);
    final _ChartStyle style = _style(context);
    final String yTitle = "Growth_axis_value".trParams(
        <String, String>{'metric': widget.metricLabel, 'unit': widget.unit});
    final String xTitle = "Growth_axis_months".tr;
    final bool anyOutside =
        widget.points.any((GrowthPoint p) => scale.isOutside(p.value));

    final Widget chart = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width = c.maxWidth;
        final double height = widget.compact ? 150 : width / 1.25;
        final _Geometry g = _Geometry(
          size: Size(width, height),
          scale: scale,
          style: style,
          yTitle: yTitle,
          xTitle: xTitle,
          compact: widget.compact,
        );
        _geometry = g;
        final Widget paint = AppChartReveal(
          revealKey: widget.metric,
          child: CustomPaint(
            size: Size(width, height),
            painter: _GrowthPainter(
              geometry: g,
              points: widget.points,
              selected: _selected,
            ),
          ),
        );
        if (widget.compact) return paint;
        return GestureDetector(
          key: const Key('growth_chart_tap'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails d) {
            final int? hit = g.nearest(widget.points, d.localPosition);
            setState(() => _selected = hit == _selected ? null : hit);
          },
          child: paint,
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: widget.semanticLabel,
          image: true,
          excludeSemantics: true,
          child: chart,
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(
          showBand: scale.band != null,
          showOutside: anyOutside,
          style: style,
        ),
        if (!widget.compact && scale.band != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text("Growth_band_caption".tr,
              key: const Key('growth_band_caption'),
              style: Theme.of(context).textTheme.bodySmall),
        ],
        if (!widget.compact && _selected != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _PointDetails(
            key: const Key('growth_point_details'),
            point: widget.points[_selected!],
            metric: widget.metric,
            sex: widget.sex,
            unit: widget.unit,
            outside: scale.isOutside(widget.points[_selected!].value),
            onClose: () => setState(() => _selected = null),
          ),
        ] else if (!widget.compact && widget.points.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text("Growth_tap_hint".tr,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Date, age, value and plain-language position of the tapped point.
class _PointDetails extends StatelessWidget {
  const _PointDetails({
    super.key,
    required this.point,
    required this.metric,
    required this.sex,
    required this.unit,
    required this.outside,
    required this.onClose,
  });

  final GrowthPoint point;
  final GrowthMetric metric;
  final String? sex;
  final String unit;
  final bool outside;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? position =
        GrowthChart.positionText(metric, sex, point.age, point.value);
    final List<String> first = <String>[
      if (point.date != null) AppDateFormat.date(point.date!),
      ageLabel(point.age.floor()),
    ];
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${GrowthChart.formatValue(point.value)} $unit',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(first.join(' · '), style: theme.textTheme.bodySmall),
                  if (position != null)
                    Text(position,
                        key: const Key('growth_point_position'),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.tertiary)),
                  if (outside)
                    Text("Growth_point_outside".tr,
                        style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// One line of colour chips: the band, the average, the baby, and the
/// edge marker when a point is outside the chart. Wraps only when the
/// text is too large for one line.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.showBand,
    required this.showOutside,
    required this.style,
  });

  final bool showBand;
  final bool showOutside;
  final _ChartStyle style;

  @override
  Widget build(BuildContext context) {
    final TextStyle? text = Theme.of(context).textTheme.bodySmall;
    Widget item(Key key, _ChipKind kind, String label) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CustomPaint(
                size: const Size(18, 12),
                painter: _ChipPainter(kind: kind, style: style)),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: text),
          ],
        );
    return ExcludeSemantics(
      child: Wrap(
        key: const Key('growth_legend'),
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (showBand) ...<Widget>[
            item(const Key('growth_legend_band'), _ChipKind.band,
                "Growth_legend_band".tr),
            item(const Key('growth_legend_average'), _ChipKind.average,
                "Growth_legend_average".tr),
          ],
          item(const Key('growth_legend_baby'), _ChipKind.baby,
              "Growth_legend_baby".tr),
          if (showOutside)
            item(const Key('growth_legend_outside'), _ChipKind.outside,
                "Growth_legend_outside".tr),
        ],
      ),
    );
  }
}

enum _ChipKind { band, average, baby, outside }

class _ChipPainter extends CustomPainter {
  _ChipPainter({required this.kind, required this.style});

  final _ChipKind kind;
  final _ChartStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    switch (kind) {
      case _ChipKind.band:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Offset.zero & size, const Radius.circular(3)),
            Paint()..color = style.band);
      case _ChipKind.average:
        canvas.drawLine(
            Offset(0, c.dy),
            Offset(size.width, c.dy),
            Paint()
              ..color = style.average
              ..strokeWidth = 2);
      case _ChipKind.baby:
        final Paint p = Paint()
          ..color = style.point
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), p);
        canvas.drawCircle(c, 4, Paint()..color = style.pointFill);
        canvas.drawCircle(c, 4, p);
      case _ChipKind.outside:
        _GrowthPainter.edgeMarker(canvas, c, up: true, color: style.outside);
    }
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.kind != kind;
}

class _ChartStyle {
  const _ChartStyle({
    required this.ink,
    required this.grid,
    required this.band,
    required this.bandEdge,
    required this.average,
    required this.point,
    required this.pointFill,
    required this.outside,
    required this.label,
    required this.title,
    required this.textScaler,
    required this.textDirection,
  });

  final Color ink, grid, band, bandEdge, average, point, pointFill, outside;
  final TextStyle label, title;
  final TextScaler textScaler;
  final TextDirection textDirection;

  TextPainter text(String s, TextStyle st) => TextPainter(
        text: TextSpan(text: s, style: st),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
}

/// Where everything goes for one size: the plot area, the ticks, and the
/// mapping from (age, value) to pixels. Shared by the painter and the tap
/// handler, so a tap lands on the point that was drawn there.
class _Geometry {
  _Geometry({
    required this.size,
    required this.scale,
    required this.style,
    required this.yTitle,
    required this.xTitle,
    required this.compact,
  }) {
    yStep = _niceStep((scale.yHi - scale.yLo) / (compact ? 3 : 5));
    yTicks = <double>[
      for (double v = (scale.yLo / yStep).ceil() * yStep;
          v <= scale.yHi + 1e-9;
          v += yStep)
        v,
    ];
    double labelW = 0;
    for (final double v in yTicks) {
      labelW = math.max(
          labelW, style.text(GrowthChart.formatValue(v), style.label).width);
    }
    final double tickH = style.text('0', style.label).height;
    final double titleH = style.text(yTitle, style.title).height;
    plot = Rect.fromLTRB(
      labelW + 8,
      titleH + 6,
      size.width - 8,
      size.height - tickH - 6 - (compact ? 0 : titleH + 4),
    );
    // Age ticks far enough apart that their labels never touch.
    final double pxPerMonth = plot.width / (scale.xHi - scale.xLo);
    final double maxLabel =
        style.text(GrowthChart.formatValue(scale.xHi), style.label).width;
    xStep = <double>[1, 2, 3, 6, 12, 24].firstWhere(
        (double s) => s * pxPerMonth >= maxLabel + 12,
        orElse: () => 24);
  }

  final Size size;
  final GrowthScale scale;
  final _ChartStyle style;
  final String yTitle;
  final String xTitle;
  final bool compact;

  late final double yStep;
  late final List<double> yTicks;
  late final double xStep;
  late final Rect plot;

  /// Left to right in every language: age grows to the right.
  Offset at(double age, double v) {
    final double fx = (age - scale.xLo) / (scale.xHi - scale.xLo);
    final double fy = (v - scale.yLo) / (scale.yHi - scale.yLo);
    return Offset(plot.left + fx * plot.width, plot.bottom - fy * plot.height);
  }

  /// Where [p] is drawn: held to the edge when outside the value axis.
  Offset of(GrowthPoint p) => at(p.age, scale.clampY(p.value));

  /// The index of the point nearest [pos] within a finger's reach (24 px),
  /// or null.
  int? nearest(List<GrowthPoint> points, Offset pos) {
    int? best;
    double bestD = 24;
    for (int i = 0; i < points.length; i++) {
      final double d = (of(points[i]) - pos).distance;
      if (d <= bestD) {
        best = i;
        bestD = d;
      }
    }
    return best;
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
}

class _GrowthPainter extends CustomPainter {
  _GrowthPainter({
    required this.geometry,
    required this.points,
    required this.selected,
  });

  final _Geometry geometry;
  final List<GrowthPoint> points;
  final int? selected;

  /// A small triangle pointing up (above the chart) or down (below it).
  static void edgeMarker(Canvas canvas, Offset c,
      {required bool up, required Color color}) {
    const double r = 6;
    final Path p = Path()
      ..moveTo(c.dx, up ? c.dy - r : c.dy + r)
      ..lineTo(c.dx - r, up ? c.dy + r * 0.7 : c.dy - r * 0.7)
      ..lineTo(c.dx + r, up ? c.dy + r * 0.7 : c.dy - r * 0.7)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final _Geometry g = geometry;
    final _ChartStyle st = g.style;
    final Rect plot = g.plot;
    final Paint gridPaint = Paint()
      ..color = st.grid
      ..strokeWidth = 1;

    // Value grid and labels.
    for (final double v in g.yTicks) {
      final double y = g.at(0, v).dy;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final TextPainter tp = st.text(GrowthChart.formatValue(v), st.label);
      tp.paint(canvas, Offset(plot.left - 6 - tp.width, y - tp.height / 2));
    }
    // Age ticks and labels.
    for (double a = g.scale.xLo; a <= g.scale.xHi + 1e-9; a += g.xStep) {
      final double x = g.at(a, g.scale.yLo).dx;
      canvas.drawLine(
          Offset(x, plot.bottom), Offset(x, plot.bottom + 4), gridPaint);
      final TextPainter tp = st.text(GrowthChart.formatValue(a), st.label);
      final double left =
          (x - tp.width / 2).clamp(0.0, size.width - tp.width).toDouble();
      tp.paint(canvas, Offset(left, plot.bottom + 5));
    }
    canvas.drawLine(Offset(plot.left, plot.bottom),
        Offset(plot.right, plot.bottom), gridPaint..color = st.ink);

    // Axis titles: value at the top left, above its labels; age centred
    // under the age labels.
    st.text(g.yTitle, st.title).paint(canvas, Offset.zero);
    if (!g.compact) {
      final TextPainter xt = st.text(g.xTitle, st.title);
      xt.paint(canvas,
          Offset(plot.center.dx - xt.width / 2, size.height - xt.height));
    }

    canvas.save();
    canvas.clipRect(plot);
    // The band and the average.
    final GrowthBand? band = g.scale.band;
    if (band != null) {
      final Path area = Path();
      for (int i = 0; i < band.upper.length; i++) {
        final Offset o = g.at(band.upper[i].age, band.upper[i].value);
        i == 0 ? area.moveTo(o.dx, o.dy) : area.lineTo(o.dx, o.dy);
      }
      for (final GrowthPoint q in band.lower.reversed) {
        final Offset o = g.at(q.age, q.value);
        area.lineTo(o.dx, o.dy);
      }
      area.close();
      canvas.drawPath(area, Paint()..color = st.band);
      final Paint edge = Paint()
        ..color = st.bandEdge
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawPath(_line(band.upper), edge);
      canvas.drawPath(_line(band.lower), edge);
      canvas.drawPath(
          _line(band.median),
          Paint()
            ..color = st.average
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
    canvas.restore();

    // The baby's points, joined.
    final Paint linePaint = Paint()
      ..color = st.point
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < points.length; i++) {
      final Offset a = g.of(points[i - 1]), b = g.of(points[i]);
      if (g.scale.isOutside(points[i - 1].value) ||
          g.scale.isOutside(points[i].value)) {
        // Towards a point held at the edge: dashed, since the line does not
        // show its real height.
        _dashed(canvas, a, b, linePaint);
      } else {
        canvas.drawLine(a, b, linePaint);
      }
    }
    final double r = g.compact ? 4 : 5;
    for (int i = 0; i < points.length; i++) {
      final GrowthPoint q = points[i];
      final Offset o = g.of(q);
      if (g.scale.isOutside(q.value)) {
        edgeMarker(canvas, o, up: q.value > g.scale.yHi, color: st.outside);
      } else {
        canvas.drawCircle(o, r, Paint()..color = st.pointFill);
        canvas.drawCircle(o, r, linePaint);
      }
      if (i == selected) {
        canvas.drawCircle(
            o,
            r + 5,
            Paint()
              ..color = st.point
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);
      }
    }
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint p) {
    final double len = (b - a).distance;
    if (len == 0) return;
    final Offset step = (b - a) / len;
    for (double d = 0; d < len; d += 9) {
      canvas.drawLine(a + step * d, a + step * math.min(d + 5, len), p);
    }
  }

  Path _line(List<GrowthPoint> line) {
    final Path path = Path();
    for (int i = 0; i < line.length; i++) {
      final Offset o = geometry.at(line[i].age, line[i].value);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_GrowthPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.geometry.size != geometry.size ||
      old.geometry.scale.yHi != geometry.scale.yHi ||
      old.geometry.style.ink != geometry.style.ink;
}
