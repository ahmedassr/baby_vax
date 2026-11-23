import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/widgets/growth_chart.dart';

/// Home's growth card: Weight | Height | Head, a compact chart of the
/// selected measure on its own axis and unit, the latest value and the
/// change since the measurement before it. Tapping the card opens Growth
/// on that measure.
class HomeGrowthCard extends StatefulWidget {
  const HomeGrowthCard({
    super.key,
    required this.measurements,
    required this.birthDate,
    required this.sex,
    required this.now,
    required this.onOpen,
  });

  /// Newest first.
  final List<MeasurementModel> measurements;
  final DateTime? birthDate;
  final String? sex;
  final DateTime now;
  final ValueChanged<GrowthMetric> onOpen;

  static String unitOf(GrowthMetric m) =>
      m == GrowthMetric.weight ? "unit_kg".tr : "unit_cm".tr;

  static String labelOf(GrowthMetric m) => switch (m) {
        GrowthMetric.weight => "weight_label".tr,
        GrowthMetric.height => "height_label".tr,
        GrowthMetric.head => "head_size_label".tr,
      };

  /// "+0.8 kg since Feb 10, 2027", "No change since …", or null for the
  /// first measurement. The signed number keeps its order in Arabic.
  static String? changeText(
      GrowthMetric m, List<MeasurementModel> oldestFirst) {
    if (oldestFirst.length < 2) return null;
    final MeasurementModel last = oldestFirst.last;
    final MeasurementModel prev = oldestFirst[oldestFirst.length - 2];
    final double d = last.valueOf(m)! - prev.valueOf(m)!;
    final String date = AppDateFormat.date(prev.date);
    final double rounded = double.parse(d.toStringAsFixed(1));
    if (rounded == 0) {
      return "Home_growth_no_change".trParams(<String, String>{'date': date});
    }
    final String n = '${rounded > 0 ? '+' : '−'}'
        '${GrowthChart.formatValue(rounded.abs())}';
    return "Home_growth_change".trParams(<String, String>{
      'change': '\u2066$n\u2069',
      'unit': unitOf(m),
      'date': date,
    });
  }

  @override
  State<HomeGrowthCard> createState() => _HomeGrowthCardState();
}

class _HomeGrowthCardState extends State<HomeGrowthCard> {
  GrowthMetric _metric = GrowthMetric.weight;

  double _ageAt(DateTime d) => widget.birthDate == null
      ? 0
      : GrowthReference.ageInMonths(widget.birthDate!, d);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GrowthMetric m = _metric;
    final List<MeasurementModel> series = widget.measurements.reversed
        .where((MeasurementModel x) => x.valueOf(m) != null)
        .toList();
    final MeasurementModel? latest = series.isEmpty ? null : series.last;
    final String? change = HomeGrowthCard.changeText(m, series);
    final double? ageNow = widget.birthDate == null
        ? null
        : GrowthReference.ageInMonths(widget.birthDate!, widget.now);
    final bool withBand = widget.sex != null &&
        ageNow != null &&
        ageNow <= GrowthReference.maxMonths;

    return AppCard(
      key: const Key('home_growth_card'),
      onTap: () => widget.onOpen(m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedButton<GrowthMetric>(
            key: const Key('home_growth_switch'),
            showSelectedIcon: false,
            segments: <ButtonSegment<GrowthMetric>>[
              for (final GrowthMetric g in GrowthMetric.values)
                ButtonSegment<GrowthMetric>(
                  value: g,
                  label: Text(
                    HomeGrowthCard.labelOf(g),
                    key: Key('home_growth_${g.name}'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
            ],
            selected: <GrowthMetric>{m},
            onSelectionChanged: (Set<GrowthMetric> s) =>
                setState(() => _metric = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          if (latest == null)
            Text(
              "Home_growth_none".trParams(
                  <String, String>{'metric': HomeGrowthCard.labelOf(m)}),
              key: const Key('home_growth_none'),
              style: theme.textTheme.bodyMedium,
            )
          else ...<Widget>[
            Text.rich(
              TextSpan(children: <InlineSpan>[
                TextSpan(
                    text: GrowthChart.formatValue(latest.valueOf(m)!),
                    style: theme.textTheme.headlineMedium),
                TextSpan(
                    text: ' ${HomeGrowthCard.unitOf(m)}',
                    style: theme.textTheme.bodyMedium),
              ]),
              key: const Key('home_growth_latest'),
            ),
            Text(
              change ?? "Home_growth_first".tr,
              key: const Key('home_growth_change'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            GrowthChart(
              key: const Key('home_growth_chart'),
              metric: m,
              compact: true,
              points: <GrowthPoint>[
                for (final MeasurementModel x in series)
                  GrowthPoint(
                      age: _ageAt(x.date), value: x.valueOf(m)!, date: x.date),
              ],
              sex: withBand ? widget.sex : null,
              unit: HomeGrowthCard.unitOf(m),
              metricLabel: HomeGrowthCard.labelOf(m),
              ageNow: ageNow,
              semanticLabel: "Growth_chart_semantic".trParams(<String, String>{
                'metric': HomeGrowthCard.labelOf(m),
                'count': '${series.length}',
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Text("Home_growth_open".tr,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
              Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}
