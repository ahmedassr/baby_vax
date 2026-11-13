import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';

import '../controller/growth_controller.dart';
import '../model/measurement_model.dart';
import '../widgets/growth_chart.dart';
import '../widgets/measurement_sheet.dart';

/// The growth tracker: pick weight, height or head; see the measurements on
/// the WHO percentile curves with a plain-language reading; the history
/// below.
class GrowthView extends GetView<GrowthController> {
  const GrowthView({super.key});

  static String unitOf(GrowthMetric m) =>
      m == GrowthMetric.weight ? "unit_kg".tr : "unit_cm".tr;

  static String labelOf(GrowthMetric m) => switch (m) {
        GrowthMetric.weight => "weight_label".tr,
        GrowthMetric.height => "height_label".tr,
        GrowthMetric.head => "head_size_label".tr,
      };

  /// "around the 50th percentile", in the current language.
  static String readingText(GrowthReading r) {
    switch (r.band) {
      case PercentileBand.below3:
        return "Growth_reading_below".tr;
      case PercentileBand.above97:
        return "Growth_reading_above".tr;
      case PercentileBand.around:
        return "Growth_reading_around"
            .trParams(<String, String>{'ord': ordinal(r.roundedPercentile)});
    }
  }

  /// "50th" in English; the bare number in Arabic ("المئين 50").
  static String ordinal(int n) {
    if ((Get.locale?.languageCode ?? 'en') != 'en') return '$n';
    final int mod100 = n % 100;
    final String suffix = (mod100 >= 11 && mod100 <= 13)
        ? 'th'
        : switch (n % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$n$suffix';
  }

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  Future<void> _add() async {
    final MeasurementSheetResult? r = await MeasurementSheet.show(
        today: controller.now, birthDate: controller.birthDate);
    if (r is SaveMeasurement) await controller.saveMeasurement(r.measurement);
  }

  Future<void> _edit(MeasurementModel m) async {
    final MeasurementSheetResult? r = await MeasurementSheet.show(
        today: controller.now, initial: m, birthDate: controller.birthDate);
    switch (r) {
      case SaveMeasurement(:final MeasurementModel measurement):
        await controller.saveMeasurement(measurement);
      case DeleteMeasurement():
        final Completer<bool> yes = Completer<bool>();
        await AppConstant.alertService.showAlert(AlertModel.attention(
          message: "Growth_delete_confirm".tr,
          yesAction: () => yes.complete(true),
          noAction: () => yes.complete(false),
        ));
        if (!yes.isCompleted) yes.complete(false);
        if (await yes.future) await controller.deleteMeasurement(m);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Growth_title".tr),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('growth_add'),
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text("Growth_add".tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoading(showHero: true);
        if (controller.loadError.value != null && controller.items.isEmpty) {
          return AppErrorState(
              message: controller.loadError.value, onRetry: controller.fetch);
        }
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: _content(context),
        );
      }),
    );
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GrowthMetric metric = controller.metric.value;
    final bool hasItems = controller.items.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 112),
      children: <Widget>[
        if (controller.actionError.value != null) ...<Widget>[
          AppBanner(
              tone: AppBannerTone.error,
              message: controller.actionError.value!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controller.savedOffline.value) ...<Widget>[
          AppBanner(
              key: const Key('growth_saved_offline'),
              icon: Icons.cloud_off_rounded,
              message: "saved_offline_msg".tr),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controller.sex == null) ...<Widget>[
          AppBanner(
            key: const Key('growth_no_sex'),
            tone: AppBannerTone.warning,
            message: "Growth_no_sex".tr,
            actionLabel: "EditUserView_edit_user_title".tr,
            onAction: () {
              AppConstant.argumentService
                  .setArgument(InternalScreenArgs(user: controller.user));
              Get.toNamed(AppRoutes.editUser);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: <Widget>[
            for (final (GrowthMetric m, IconData icon)
                in <(GrowthMetric, IconData)>[
              (GrowthMetric.weight, Icons.monitor_weight_outlined),
              (GrowthMetric.height, Icons.straighten_rounded),
              (GrowthMetric.head, Icons.face_rounded),
            ]) ...<Widget>[
              if (m != GrowthMetric.weight)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppChoiceTile(
                  key: Key('growth_metric_${m.name}'),
                  label: labelOf(m),
                  icon: icon,
                  selected: metric == m,
                  onTap: () => controller.setMetric(m),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (!hasItems)
          AppEmptyState(
            scrollable: false,
            icon: Icons.show_chart_rounded,
            title: "Growth_empty_title".tr,
            message: "Growth_empty_body".tr,
            actionLabel: "Growth_add".tr,
            onAction: _add,
          )
        else ...<Widget>[
          _readingCard(theme, metric),
          const SizedBox(height: AppSpacing.md),
          _chartCard(theme, metric),
        ],
        if (hasItems) ...<Widget>[
          AppSectionHeader(title: "Growth_history".tr),
          for (final MeasurementModel m in controller.items) ...<Widget>[
            _historyRow(theme, m),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        const MedicalDisclaimer(compact: true),
        const SizedBox(height: AppSpacing.sm),
        Text("Growth_attribution".tr, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _readingCard(ThemeData theme, GrowthMetric metric) {
    final MeasurementModel? latest = controller.latest;
    final GrowthReading? reading = controller.latestReading;
    return AppCard(
      key: const Key('growth_reading'),
      child: latest == null
          ? Text("Growth_no_value_for_metric".tr,
              style: theme.textTheme.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(TextSpan(children: <InlineSpan>[
                  TextSpan(
                      text: _num(latest.valueOf(metric)!),
                      style: theme.textTheme.headlineMedium),
                  TextSpan(
                      text: ' ${unitOf(metric)}',
                      style: theme.textTheme.bodyMedium),
                ])),
                Text(
                  '${AppDateFormat.date(latest.date)} · '
                  '${ageLabel(controller.ageAt(latest).floor())}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                if (reading != null) ...<Widget>[
                  Text(readingText(reading),
                      key: const Key('growth_reading_text'),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.tertiary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text("Growth_reading_note".tr,
                      style: theme.textTheme.bodySmall),
                ] else if (controller.sex != null)
                  Text("Growth_over_five".tr, style: theme.textTheme.bodySmall),
              ],
            ),
    );
  }

  Widget _chartCard(ThemeData theme, GrowthMetric metric) {
    final List<GrowthPoint> points = <GrowthPoint>[
      for (final MeasurementModel m in controller.series)
        (age: controller.ageAt(m), value: m.valueOf(metric)!),
    ];
    final bool curves = controller.percentilesAvailable;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GrowthChart(
            key: const Key('growth_chart'),
            metric: metric,
            points: points,
            sex: curves ? controller.sex : null,
            unit: unitOf(metric),
            ageNow: controller.ageNow,
            semanticLabel: "Growth_chart_semantic".trParams(<String, String>{
              'metric': labelOf(metric),
              'count': '${points.length}',
            }),
          ),
          if (curves)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text("Growth_legend".tr, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _historyRow(ThemeData theme, MeasurementModel m) {
    final List<String> parts = <String>[
      for (final GrowthMetric g in GrowthMetric.values)
        if (m.valueOf(g) != null)
          '${labelOf(g)} ${_num(m.valueOf(g)!)} ${unitOf(g)}',
    ];
    return AppCard(
      onTap: () => _edit(m),
      semanticLabel:
          '${AppDateFormat.date(m.date)}, ${parts.join(', ')}${m.note == null ? '' : ', ${m.note}'}',
      child: Row(
        children: <Widget>[
          const AppIconBadge(icon: Icons.straighten_rounded, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppDateFormat.date(m.date),
                    style: theme.textTheme.titleSmall),
                Text(parts.join(' · '), style: theme.textTheme.bodyMedium),
                if (m.note != null)
                  Text(bidiIsolate(m.note!),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.edit_outlined,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
