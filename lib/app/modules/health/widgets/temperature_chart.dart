import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';

import '../model/health_entry.dart';
import 'health_labels.dart';

/// A vaccine dose given in the chart's period, shown as a marker.
class ChartDose {
  const ChartDose({required this.at, required this.dose});

  /// The day it was given (or its scheduled day when no date was recorded).
  final DateTime at;
  final MedicalDatesModel dose;
}

/// What a tap on the chart picked.
sealed class TemperatureChartPick {
  const TemperatureChartPick();
}

class PickedEntry extends TemperatureChartPick {
  const PickedEntry(this.entry);

  final HealthEntry entry;
}

class PickedDose extends TemperatureChartPick {
  const PickedDose(this.dose);

  final ChartDose dose;
}

/// Logged temperatures over the last [days] days, with WHO's fever figure
/// (37.5 °C, armpit; from the guidance pinned in `health_guidance.dart`) as
/// a dashed line, and markers for vaccine doses given and medicines logged
/// in the same period. Time always runs left to right, in Arabic too.
///
/// Tap a reading or a marker to see it; the panel under the chart opens the
/// entry or the dose.
class TemperatureChart extends StatefulWidget {
  const TemperatureChart({
    super.key,
    required this.readings,
    required this.medicines,
    required this.doses,
    required this.now,
    required this.days,
    required this.onOpenEntry,
    required this.onOpenDose,
  });

  /// Temperature entries in the period, oldest first.
  final List<HealthEntry> readings;

  /// Medicine entries in the period.
  final List<HealthEntry> medicines;
  final List<ChartDose> doses;
  final DateTime now;
  final int days;
  final ValueChanged<HealthEntry> onOpenEntry;
  final ValueChanged<MedicalDatesModel> onOpenDose;

  /// Whether [e] is at or above WHO's fever figure for its method.
  static bool isFever(HealthEntry e) =>
      HealthGuidance.isFever(e.tempC!, e.method ?? TemperatureMethod.armpit) ??
      false;

  @override
  State<TemperatureChart> createState() => TemperatureChartState();
}

/// Public so tests can find where each mark was drawn.
class TemperatureChartState extends State<TemperatureChart> {
  TemperatureChartPick? _picked;
  _TempGeometry? _geometry;

  /// Where each reading was last drawn, in the chart's coordinates.
  @visibleForTesting
  List<Offset> get readingOffsets => <Offset>[
        if (_geometry != null)
          for (final HealthEntry e in widget.readings) _geometry!.reading(e),
      ];

  /// Where each medicine marker was last drawn.
  @visibleForTesting
  List<Offset> get medicineOffsets => <Offset>[
        if (_geometry != null)
          for (final HealthEntry e in widget.medicines) _geometry!.marker(e.at),
      ];

  /// Where each dose marker was last drawn.
  @visibleForTesting
  List<Offset> get doseOffsets => <Offset>[
        if (_geometry != null)
          for (final ChartDose d in widget.doses) _geometry!.marker(d.at),
      ];

  @override
  void didUpdateWidget(TemperatureChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days ||
        oldWidget.readings.length != widget.readings.length) {
      _picked = null;
    }
  }

  TemperatureChartPick? _hit(_TempGeometry g, Offset pos) {
    TemperatureChartPick? best;
    double bestD = 24;
    void consider(Offset o, TemperatureChartPick p) {
      final double d = (o - pos).distance;
      if (d <= bestD) {
        bestD = d;
        best = p;
      }
    }

    for (final HealthEntry e in widget.readings) {
      consider(g.reading(e), PickedEntry(e));
    }
    for (final HealthEntry e in widget.medicines) {
      consider(g.marker(e.at), PickedEntry(e));
    }
    for (final ChartDose d in widget.doses) {
      consider(g.marker(d.at), PickedDose(d));
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final _TempStyle style = _TempStyle(
      line: scheme.primary,
      fever: scheme.error,
      dose: scheme.tertiary,
      medicine: scheme.secondary,
      grid: scheme.outlineVariant,
      ink: scheme.onSurfaceVariant,
      surface: scheme.surface,
      label:
          theme.textTheme.labelSmall!.copyWith(color: scheme.onSurfaceVariant),
      title: theme.textTheme.labelMedium!.copyWith(color: scheme.onSurface),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    );
    final double highest = widget.readings.isEmpty
        ? 0
        : widget.readings.map((HealthEntry e) => e.tempC!).reduce(math.max);

    final Widget chart = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final Size size = Size(c.maxWidth, 200);
        final _TempGeometry g = _TempGeometry(
          size: size,
          style: style,
          readings: widget.readings,
          now: widget.now,
          days: widget.days,
          yTitle: "Health_axis_temperature".tr,
          xTitle: "Health_axis_date".tr,
        );
        _geometry = g;
        return GestureDetector(
          key: const Key('health_chart_tap'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (TapUpDetails d) {
            final TemperatureChartPick? hit = _hit(g, d.localPosition);
            setState(() => _picked = hit);
          },
          child: CustomPaint(
            size: size,
            painter: _TemperaturePainter(
              geometry: g,
              readings: widget.readings,
              medicines: widget.medicines,
              doses: widget.doses,
              picked: _picked,
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: "Health_chart_semantic".trParams(<String, String>{
            'count': '${widget.readings.length}',
            'max': highest.toStringAsFixed(1),
          }),
          image: true,
          excludeSemantics: true,
          child: SizedBox(key: const Key('health_chart'), child: chart),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: Wrap(
            key: const Key('health_chart_legend'),
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _chip(context, _Mark.reading, style, "Health_legend_reading".tr),
              _chip(context, _Mark.fever, style, "Health_legend_fever".tr),
              if (widget.doses.isNotEmpty)
                _chip(context, _Mark.dose, style, "Health_legend_dose".tr),
              if (widget.medicines.isNotEmpty)
                _chip(context, _Mark.medicine, style,
                    "Health_legend_medicine".tr),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Health_chart_source".trParams(<String, String>{
            'fever': HealthGuidance.feverArmpitC.toStringAsFixed(1),
            'rectal': HealthGuidance.rectalOffsetC.toStringAsFixed(1),
          }),
          key: const Key('health_chart_source'),
          style: theme.textTheme.bodySmall,
        ),
        if (widget.readings.length == 1) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text("Health_chart_one".tr,
              key: const Key('health_chart_one'),
              style: theme.textTheme.bodySmall),
        ],
        if (_picked != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _PickedPanel(
            key: const Key('health_chart_details'),
            picked: _picked!,
            onOpen: () {
              final TemperatureChartPick p = _picked!;
              switch (p) {
                case PickedEntry(:final HealthEntry entry):
                  widget.onOpenEntry(entry);
                case PickedDose(:final ChartDose dose):
                  widget.onOpenDose(dose.dose);
              }
            },
            onClose: () => setState(() => _picked = null),
          ),
        ] else ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text("Health_chart_tap_hint".tr, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _chip(
          BuildContext context, _Mark mark, _TempStyle style, String label) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CustomPaint(
              size: const Size(18, 12),
              painter: _ChipPainter(mark: mark, style: style)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

/// The tapped reading, medicine or dose, with a button that opens it.
class _PickedPanel extends StatelessWidget {
  const _PickedPanel({
    super.key,
    required this.picked,
    required this.onOpen,
    required this.onClose,
  });

  final TemperatureChartPick picked;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (String title, String subtitle) = switch (picked) {
      PickedEntry(:final HealthEntry entry)
          when entry.kind == HealthEntryKind.temperature =>
        (
          HealthLabels.temperature(entry.tempC!),
          <String>[
            if (entry.method != null) HealthLabels.method(entry.method!),
            AppDateFormat.dateTime(entry.at),
          ].join(' · '),
        ),
      PickedEntry(:final HealthEntry entry) => (
          "Health_chart_medicine".trParams(
              <String, String>{'name': bidiIsolate(entry.medicine ?? '')}),
          <String>[
            if (entry.amount != null) bidiIsolate(entry.amount!),
            AppDateFormat.dateTime(entry.at),
          ].join(' · '),
        ),
      PickedDose(:final ChartDose dose) => (
          "Health_chart_dose_given".trParams(
              <String, String>{'vaccine': bidiIsolate(dose.dose.displayName)}),
          AppDateFormat.date(dose.at),
        ),
    };
    final String open = picked is PickedDose
        ? "Health_chart_open_dose".tr
        : "Health_chart_open_entry".tr;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(subtitle, style: theme.textTheme.bodySmall),
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const Key('health_chart_open'),
                onPressed: onOpen,
                child: Text(open),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Mark { reading, fever, dose, medicine }

class _TempStyle {
  const _TempStyle({
    required this.line,
    required this.fever,
    required this.dose,
    required this.medicine,
    required this.grid,
    required this.ink,
    required this.surface,
    required this.label,
    required this.title,
    required this.textScaler,
    required this.textDirection,
  });

  final Color line, fever, dose, medicine, grid, ink, surface;
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

/// Plot area, ticks and the time/°C to pixel mapping for one size.
class _TempGeometry {
  _TempGeometry({
    required this.size,
    required this.style,
    required this.readings,
    required this.now,
    required this.days,
    required this.yTitle,
    required this.xTitle,
  }) {
    final List<double> values = <double>[
      for (final HealthEntry e in readings) e.tempC!
    ];
    // Always show the fever line, with room around the readings.
    lo = (math.min(values.fold(36.0, math.min), 36.0) - 0.5).floorToDouble();
    hi = (math.max(values.fold(HealthGuidance.feverArmpitC, math.max),
                HealthGuidance.feverArmpitC) +
            0.5)
        .ceilToDouble();
    from = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    to = now;

    double labelW = 0;
    for (double c = lo; c <= hi; c += 1) {
      labelW =
          math.max(labelW, style.text(c.toStringAsFixed(0), style.label).width);
    }
    final double tickH = style.text('0', style.label).height;
    final double titleH = style.text(yTitle, style.title).height;
    plot = Rect.fromLTRB(labelW + 8, titleH + 6, size.width - 8,
        size.height - tickH - titleH - 10);

    // Day ticks spaced so their labels never touch.
    final double maxLabel = style
        .text(AppDateFormat.dayMonth(DateTime(2027, 12, 30)), style.label)
        .width;
    final double pxPerDay =
        plot.width / (to.difference(from).inMinutes / (24 * 60));
    dayStep = <int>[1, 2, 3, 7, 14]
        .firstWhere((int s) => s * pxPerDay >= maxLabel + 10, orElse: () => 14);
  }

  final Size size;
  final _TempStyle style;
  final List<HealthEntry> readings;
  final DateTime now;
  final int days;
  final String yTitle;
  final String xTitle;

  late final double lo, hi;
  late final DateTime from, to;
  late final Rect plot;
  late final int dayStep;

  /// Left to right in every language.
  double x(DateTime t) {
    final double f =
        (t.difference(from).inMinutes / to.difference(from).inMinutes)
            .clamp(0.0, 1.0);
    return plot.left + f * plot.width;
  }

  double y(double c) => plot.top + (hi - c) / (hi - lo) * plot.height;

  Offset reading(HealthEntry e) => Offset(x(e.at), y(e.tempC!));

  /// Markers sit on a lane just above the time axis.
  Offset marker(DateTime t) => Offset(x(t), plot.bottom - 8);
}

class _TemperaturePainter extends CustomPainter {
  _TemperaturePainter({
    required this.geometry,
    required this.readings,
    required this.medicines,
    required this.doses,
    required this.picked,
  });

  final _TempGeometry geometry;
  final List<HealthEntry> readings;
  final List<HealthEntry> medicines;
  final List<ChartDose> doses;
  final TemperatureChartPick? picked;

  static void mark(Canvas canvas, _Mark m, Offset c, _TempStyle st) {
    switch (m) {
      case _Mark.reading:
        canvas.drawCircle(c, 4.5, Paint()..color = st.line);
      case _Mark.fever:
        canvas.drawCircle(c, 4.5, Paint()..color = st.fever);
      case _Mark.dose:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: c, width: 11, height: 11),
                const Radius.circular(2)),
            Paint()..color = st.dose);
      case _Mark.medicine:
        final Path p = Path()
          ..moveTo(c.dx, c.dy - 6)
          ..lineTo(c.dx + 6, c.dy)
          ..lineTo(c.dx, c.dy + 6)
          ..lineTo(c.dx - 6, c.dy)
          ..close();
        canvas.drawPath(p, Paint()..color = st.medicine);
    }
  }

  static void dashed(Canvas canvas, Offset a, Offset b, Paint p) {
    final double len = (b - a).distance;
    if (len == 0) return;
    final Offset step = (b - a) / len;
    for (double d = 0; d < len; d += 8) {
      canvas.drawLine(a + step * d, a + step * math.min(d + 4, len), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final _TempGeometry g = geometry;
    final _TempStyle st = g.style;
    final Rect plot = g.plot;
    final Paint gridPaint = Paint()
      ..color = st.grid
      ..strokeWidth = 1;

    for (double c = g.lo; c <= g.hi; c += 1) {
      final double yy = g.y(c);
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), gridPaint);
      final TextPainter tp = st.text(c.toStringAsFixed(0), st.label);
      tp.paint(canvas, Offset(plot.left - 6 - tp.width, yy - tp.height / 2));
    }
    // Day ticks, counted back from today so today always has one.
    final DateTime today = DateTime(g.now.year, g.now.month, g.now.day);
    for (int i = 0; i < g.days; i += g.dayStep) {
      final DateTime day = today.subtract(Duration(days: i));
      final double xx = g.x(day);
      canvas.drawLine(Offset(xx, plot.top), Offset(xx, plot.bottom), gridPaint);
      final TextPainter tp = st.text(AppDateFormat.dayMonth(day), st.label);
      final double left =
          (xx - tp.width / 2).clamp(0.0, size.width - tp.width).toDouble();
      tp.paint(canvas, Offset(left, plot.bottom + 4));
    }
    canvas.drawLine(Offset(plot.left, plot.bottom),
        Offset(plot.right, plot.bottom), Paint()..color = st.ink);
    st.text(g.yTitle, st.title).paint(canvas, Offset.zero);
    final TextPainter xt = st.text(g.xTitle, st.title);
    xt.paint(
        canvas, Offset(plot.center.dx - xt.width / 2, size.height - xt.height));

    // WHO's fever figure, dashed.
    final double fy = g.y(HealthGuidance.feverArmpitC);
    dashed(
        canvas,
        Offset(plot.left, fy),
        Offset(plot.right, fy),
        Paint()
          ..color = st.fever
          ..strokeWidth = 1.5);

    // Markers for doses and medicines.
    for (final ChartDose d in doses) {
      mark(canvas, _Mark.dose, g.marker(d.at), st);
    }
    for (final HealthEntry e in medicines) {
      mark(canvas, _Mark.medicine, g.marker(e.at), st);
    }

    // The readings.
    final Paint linePaint = Paint()
      ..color = st.line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 1; i < readings.length; i++) {
      canvas.drawLine(
          g.reading(readings[i - 1]), g.reading(readings[i]), linePaint);
    }
    for (final HealthEntry e in readings) {
      mark(canvas, TemperatureChart.isFever(e) ? _Mark.fever : _Mark.reading,
          g.reading(e), st);
    }

    // The tapped one.
    final Offset? sel = switch (picked) {
      PickedEntry(:final HealthEntry entry)
          when entry.kind == HealthEntryKind.temperature =>
        g.reading(entry),
      PickedEntry(:final HealthEntry entry) => g.marker(entry.at),
      PickedDose(:final ChartDose dose) => g.marker(dose.at),
      null => null,
    };
    if (sel != null) {
      canvas.drawCircle(
          sel,
          10,
          Paint()
            ..color = st.line
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_TemperaturePainter old) =>
      old.readings != readings ||
      old.picked != picked ||
      old.geometry.size != geometry.size ||
      old.geometry.days != geometry.days ||
      old.geometry.style.line != geometry.style.line;
}

class _ChipPainter extends CustomPainter {
  _ChipPainter({required this.mark, required this.style});

  final _Mark mark;
  final _TempStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    switch (mark) {
      case _Mark.reading:
        canvas.drawLine(
            Offset(0, c.dy),
            Offset(size.width, c.dy),
            Paint()
              ..color = style.line
              ..strokeWidth = 2);
        _TemperaturePainter.mark(canvas, _Mark.reading, c, style);
      case _Mark.fever:
        _TemperaturePainter.dashed(
            canvas,
            Offset(0, c.dy),
            Offset(size.width, c.dy),
            Paint()
              ..color = style.fever
              ..strokeWidth = 2);
      case _Mark.dose:
      case _Mark.medicine:
        _TemperaturePainter.mark(canvas, mark, c, style);
    }
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.mark != mark;
}
