import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';

/// Texts for a milestone, in the current language.
class MilestoneText {
  const MilestoneText._();

  static String name(MotorMilestone m) => "Milestone_${m.id}_name".tr;

  /// The plain "what counts" wording of WHO's performance criteria.
  static String criteria(MotorMilestone m) => "Milestone_${m.id}_criteria".tr;

  static String status(MilestoneStatus s) => "Milestone_status_${s.name}".tr;

  /// "3.8", "9.2", "12": months as the WHO table gives them, Western digits.
  static String months(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// "Most babies: between 3.8 and 9.2 months".
  /// Each number is isolated, so "و13.7" in Arabic keeps
  /// the "و" before the number.
  static String range(MotorMilestone m) =>
      "Milestone_range".trParams(<String, String>{
        'from': bidiIsolate(months(m.startMonths)),
        'to': bidiIsolate(months(m.endMonths)),
      });

  /// The line under a milestone's bar.
  static String line(MotorMilestone m, DateTime? achievedAt) {
    if (achievedAt != null) {
      return "Milestone_achieved_on"
          .trParams(<String, String>{'date': AppDateFormat.date(achievedAt)});
    }
    if (m.optional) return "Milestone_crawling_skip".tr;
    return range(m);
  }

  /// The age in words, "10 months", "2 years".
  static String age(double months) => ageLabel(months.floor());
}

/// The age range every milestone bar is drawn on: 0 to 18 months, longer
/// when the baby is older.
class MilestoneScale {
  const MilestoneScale(this.maxMonths, this.step);

  /// The right end of the scale, in months.
  final double maxMonths;

  /// Months between tick labels.
  final int step;

  static MilestoneScale forAge(double? ageMonths) {
    final double age = ageMonths ?? 0;
    if (age <= 18) return const MilestoneScale(18, 6);
    final int step = age <= 24 ? 6 : 12;
    return MilestoneScale((age / step).ceil() * step.toDouble(), step);
  }

  List<int> get ticks => <int>[
        for (int t = 0; t <= maxMonths; t += step) t,
      ];

  /// Horizontal position of [months] on a bar [width] wide, from the left
  /// (age 0) in every language.
  double x(double months, double width) =>
      (months.clamp(0, maxMonths) / maxMonths) * width;
}

/// The month labels above the list (0, 6, 12, 18), on the same scale as
/// every bar. Always left to right.
class MilestoneScaleHeader extends StatelessWidget {
  const MilestoneScaleHeader({super.key, required this.scale});

  final MilestoneScale scale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Milestones_scale_title".tr, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xxs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: ExcludeSemantics(
            child: SizedBox(
              height: 20 * MediaQuery.textScalerOf(context).scale(1),
              child: Stack(
                children: <Widget>[
                  for (final int t in scale.ticks)
                    Align(
                      // -1 is the left edge and 1 the right: the label sits
                      // over its month and never runs off the bar.
                      alignment: Alignment(-1 + 2 * t / scale.maxMonths, 0),
                      child: Text('$t',
                          key: Key('milestone_tick_$t'), style: style),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One milestone on the shared age scale: the WHO window as a shaded
/// segment, a thin dark line at the baby's age today, and a dot at the age
/// it was achieved. Drawn left to right (age 0 on the left) in every
/// language, like every other time axis in the app.
class MilestoneBar extends StatelessWidget {
  const MilestoneBar({
    super.key,
    required this.milestone,
    required this.scale,
    this.ageNow,
    this.achievedAge,
  });

  final MotorMilestone milestone;
  final MilestoneScale scale;
  final double? ageNow;
  final double? achievedAge;

  static const double height = 28;
  static const double _track = 12;
  static const double _dot = 14;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final String id = milestone.id;
    final String semantic = <String>[
      "Milestone_bar_semantic".trParams(<String, String>{
        'from': MilestoneText.months(milestone.startMonths),
        'to': MilestoneText.months(milestone.endMonths),
        'age': ageNow == null ? '-' : MilestoneText.age(ageNow!),
      }),
      if (achievedAge != null)
        "Milestone_bar_semantic_done".trParams(
            <String, String>{'done': MilestoneText.age(achievedAge!)}),
    ].join(' ');

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          key: Key('milestone_bar_$id'),
          height: height,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double w = c.maxWidth;
              const double trackTop = (height - _track) / 2;
              final double from = scale.x(milestone.startMonths, w);
              final double to = scale.x(milestone.endMonths, w);
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: trackTop,
                    height: _track,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: s.surfaceContainerHighest,
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                  ),
                  Positioned(
                    key: Key('milestone_window_$id'),
                    left: from,
                    width: math.max(to - from, 2),
                    top: trackTop,
                    height: _track,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: s.primaryContainer,
                        border:
                            Border.all(color: s.primary.withValues(alpha: 0.5)),
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                  ),
                  if (achievedAge != null)
                    Positioned(
                      key: Key('milestone_dot_$id'),
                      left: scale.x(achievedAge!, w) - _dot / 2,
                      top: (height - _dot) / 2,
                      width: _dot,
                      height: _dot,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: s.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.surface, width: 2),
                        ),
                      ),
                    ),
                  if (ageNow != null)
                    Positioned(
                      key: Key('milestone_now_$id'),
                      left: scale.x(ageNow!, w) - 1,
                      top: 0,
                      width: 2,
                      height: height,
                      child: ColoredBox(color: s.onSurface),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A milestone's status as a small pill, with an icon as well as a colour.
class MilestoneStatusChip extends StatelessWidget {
  const MilestoneStatusChip({super.key, required this.status});

  final MilestoneStatus status;

  static IconData iconFor(MilestoneStatus s) => switch (s) {
        MilestoneStatus.achieved => Icons.check_circle_rounded,
        MilestoneStatus.dueNow => Icons.schedule_rounded,
        MilestoneStatus.later => Icons.more_time_rounded,
        MilestoneStatus.optional => Icons.radio_button_unchecked_rounded,
        MilestoneStatus.pastWindow => Icons.edit_calendar_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStatusColors colors = AppStatusColors.of(context);
    // Calm colours only: green when achieved, the pending colour when its
    // time is now, neutral otherwise. Never the error colour.
    final (Color bg, Color fg) = switch (status) {
      MilestoneStatus.achieved => (
          colors.completedBackground,
          colors.completedForeground
        ),
      MilestoneStatus.dueNow => (
          colors.pendingBackground,
          colors.pendingForeground
        ),
      _ => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant
        ),
    };
    final String label = MilestoneText.status(status);
    return Semantics(
      label:
          "status_semantic_label".trParams(<String, String>{'status': label}),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(iconFor(status), size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "dark line = baby's age now, shaded area = when most babies do it, dot =
/// date achieved", as chips that wrap on a narrow screen.
class MilestonesLegend extends StatelessWidget {
  const MilestonesLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme s = theme.colorScheme;
    Widget item(Key key, Widget swatch, String label) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(width: 16, height: 16, child: Center(child: swatch)),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(label, style: theme.textTheme.bodySmall)),
          ],
        );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        item(
          const Key('milestones_legend_now'),
          SizedBox(width: 2, height: 16, child: ColoredBox(color: s.onSurface)),
          "Milestones_legend_now".tr,
        ),
        item(
          const Key('milestones_legend_window'),
          Container(
            width: 16,
            height: 10,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              border: Border.all(color: s.primary.withValues(alpha: 0.5)),
              borderRadius: AppRadius.pillAll,
            ),
          ),
          "Milestones_legend_window".tr,
        ),
        item(
          const Key('milestones_legend_dot'),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: s.primary, shape: BoxShape.circle),
          ),
          "Milestones_legend_dot".tr,
        ),
      ],
    );
  }
}
