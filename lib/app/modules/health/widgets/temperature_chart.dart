import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';

import '../model/health_entry.dart';

/// The last 72 hours of temperatures as a line, with WHO's fever figure
/// (37.5 °C, armpit) as a dashed line. Time runs with the reading
/// direction: left to right in English, right to left in Arabic.
class TemperatureChart extends StatelessWidget {
  const TemperatureChart({
    super.key,
    required this.readings,
    required this.now,
    this.window = const Duration(hours: 72),
  });

  /// Oldest first.
  final List<HealthEntry> readings;
  final DateTime now;
  final Duration window;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double highest =
        readings.map((HealthEntry e) => e.tempC!).reduce(math.max);
    final Widget chart = Semantics(
      label: "Health_chart_semantic".trParams(<String, String>{
        'count': '${readings.length}',
        'max': highest.toStringAsFixed(1),
      }),
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('health_chart'),
        height: 160,
        child: CustomPaint(
          painter: _TemperaturePainter(
            readings: readings,
            now: now,
            window: window,
            rtl: Directionality.of(context) == TextDirection.rtl,
            line: scheme.primary,
            point: scheme.primary,
            fever: scheme.error,
            grid: scheme.outlineVariant,
            label: theme.textTheme.labelSmall!
                .copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        chart,
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            ExcludeSemantics(
              child: Text('- - -',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.error)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text("Health_chart_legend".tr,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ],
    );
  }
}

class _TemperaturePainter extends CustomPainter {
  _TemperaturePainter({
    required this.readings,
    required this.now,
    required this.window,
    required this.rtl,
    required this.line,
    required this.point,
    required this.fever,
    required this.grid,
    required this.label,
  });

  final List<HealthEntry> readings;
  final DateTime now;
  final Duration window;
  final bool rtl;
  final Color line;
  final Color point;
  final Color fever;
  final Color grid;
  final TextStyle label;

  static const double _left = 36;
  static const double _bottom = 8;
  static const double _top = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> values = <double>[for (final e in readings) e.tempC!];
    // Always show the fever line, with some room around the readings.
    final double lo =
        (math.min(values.reduce(math.min), 36.0) - 0.5).floorToDouble();
    final double hi =
        (math.max(values.reduce(math.max), HealthGuidance.feverArmpitC) + 0.5)
            .ceilToDouble();
    final double w = size.width - _left;
    final double h = size.height - _top - _bottom;
    final DateTime from = now.subtract(window);

    double x(DateTime t) {
      final double f =
          (t.difference(from).inMinutes / window.inMinutes).clamp(0.0, 1.0);
      final double inPlot = _left + f * w;
      return rtl ? size.width - inPlot + 0 : inPlot;
    }

    double y(double c) => _top + (hi - c) / (hi - lo) * h;

    // Whole-degree grid lines with labels on the start side.
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (double c = lo; c <= hi; c += 1) {
      final double yy = y(c);
      canvas.drawLine(Offset(rtl ? 0 : _left, yy),
          Offset(rtl ? size.width - _left : size.width, yy), gridPaint);
      _text(canvas, c.toStringAsFixed(0), label,
          Offset(rtl ? size.width - _left + 4 : 0, yy - 7));
    }

    // WHO's fever figure, dashed.
    final double fy = y(HealthGuidance.feverArmpitC);
    final Paint feverPaint = Paint()
      ..color = fever
      ..strokeWidth = 1.5;
    final double start = rtl ? 0 : _left;
    final double end = rtl ? size.width - _left : size.width;
    for (double sx = start; sx < end; sx += 8) {
      canvas.drawLine(
          Offset(sx, fy), Offset(math.min(sx + 4, end), fy), feverPaint);
    }
    // Explained by the legend under the chart, so no label sits on the
    // newest readings.

    // The readings.
    final Paint linePaint = Paint()
      ..color = line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Path path = Path();
    for (int i = 0; i < readings.length; i++) {
      final Offset p = Offset(x(readings[i].at), y(values[i]));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);
    final Paint dot = Paint()..color = point;
    for (int i = 0; i < readings.length; i++) {
      canvas.drawCircle(Offset(x(readings[i].at), y(values[i])), 4, dot);
    }
  }

  void _text(Canvas canvas, String s, TextStyle style, Offset at) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _left - 4);
    tp.paint(canvas, at);
    tp.dispose();
  }

  @override
  bool shouldRepaint(_TemperaturePainter old) =>
      old.readings != readings || old.now != now || old.rtl != rtl;
}
