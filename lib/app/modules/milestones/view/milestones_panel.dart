import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';

import '../controller/milestones_controller.dart';
import '../model/milestone_record.dart';
import '../widgets/milestone_bar.dart';
import '../widgets/milestone_sheet.dart';

/// The sheets behind "Done", "Edit" and "Add a note", shared by the list
/// and the details screen.
class MilestoneActions {
  const MilestoneActions(this.controller);

  final MilestonesController controller;

  /// Record the date (or edit it); "Remove" asks first.
  Future<void> record(MotorMilestone m) async {
    final MilestoneSheetResult? r = await MilestoneSheet.show(
      milestone: m,
      today: controller.now,
      initial: controller.recordOf(m),
      birthDate: controller.birthDate,
    );
    switch (r) {
      case SaveMilestone(:final MilestoneRecord record):
        await controller.saveRecord(record);
      case RemoveMilestone():
        final bool yes = await controller.confirmRemove(
            "Milestone_remove_confirm"
                .trParams(<String, String>{'name': MilestoneText.name(m)}));
        if (yes) await controller.removeAchievement(m);
      case null:
        break;
    }
  }

  /// The note for the doctor visit, kept with the milestone.
  Future<void> note(MotorMilestone m) async {
    final MilestoneSheetResult? r = await MilestoneSheet.show(
      milestone: m,
      today: controller.now,
      initial: controller.recordOf(m),
      birthDate: controller.birthDate,
      noteOnly: true,
    );
    if (r is SaveMilestone) {
      await controller.saveNote(m, r.record.note ?? '');
    }
  }

  void openDetails(MotorMilestone m) =>
      Get.toNamed(AppRoutes.milestoneDetails, arguments: m.id);
}

/// The Milestones half of the Growth screen: a summary, the six WHO motor
/// milestones on one age scale, and a legend.
class MilestonesPanel extends GetView<MilestonesController> {
  const MilestonesPanel({super.key});

  /// The cards' inner padding, which the scale header above them shares so
  /// its labels sit over the bars.
  static const double inner = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading();
      if (controller.loadError.value != null && controller.records.isEmpty) {
        return AppErrorState(
            message: controller.loadError.value, onRetry: controller.fetch);
      }
      return RefreshIndicator(
        onRefresh: controller.fetch,
        child: _list(context),
      );
    });
  }

  Widget _list(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MilestoneActions actions = MilestoneActions(controller);
    final double? age = controller.ageNow;
    final MilestoneScale scale = MilestoneScale.forAge(age);
    return ListView(
      key: const Key('milestones_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      children: <Widget>[
        if (controller.actionError.value != null) ...<Widget>[
          AppBanner(
              tone: AppBannerTone.error,
              message: controller.actionError.value!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controller.savedOffline.value) ...<Widget>[
          AppBanner(
              key: const Key('milestones_saved_offline'),
              icon: Icons.cloud_off_rounded,
              message: "saved_offline_msg".tr),
          const SizedBox(height: AppSpacing.md),
        ],
        _summary(theme, age),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: inner),
          child: MilestoneScaleHeader(
              key: const Key('milestones_scale'), scale: scale),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final MotorMilestone m in MotorMilestone.values) ...<Widget>[
          MilestoneCard(
            milestone: m,
            scale: scale,
            controller: controller,
            onTap: () => actions.openDetails(m),
            onRecord: () => actions.record(m),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        const MilestonesLegend(key: Key('milestones_legend')),
        const SizedBox(height: AppSpacing.lg),
        Text("Milestone_source".tr, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _summary(ThemeData theme, double? age) {
    final int done = controller.achievedCount;
    final int total = MotorMilestone.values.length;
    return AppCard(
      key: const Key('milestones_summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            age == null
                ? controller.childName
                : "Milestones_summary_age".trParams(<String, String>{
                    'name': bidiIsolate(controller.childName),
                    'age': ageLabel(controller.wholeMonthsNow),
                  }),
            key: const Key('milestones_summary_title'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Milestones_count"
                .trParams(<String, String>{'done': '$done', 'total': '$total'}),
            key: const Key('milestones_count'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              key: const Key('milestones_progress'),
              value: done / total,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text("Milestones_summary_note".tr, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One milestone in the list: name and status, the bar on the shared
/// scale, one line of text, and "Done" or "Edit".
class MilestoneCard extends StatelessWidget {
  const MilestoneCard({
    super.key,
    required this.milestone,
    required this.scale,
    required this.controller,
    required this.onTap,
    required this.onRecord,
  });

  final MotorMilestone milestone;
  final MilestoneScale scale;
  final MilestonesController controller;
  final VoidCallback onTap;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String id = milestone.id;
    final MilestoneRecord? r = controller.recordOf(milestone);
    final DateTime? at = r?.achievedAt;
    final MilestoneStatus status = controller.statusOf(milestone);
    return AppCard(
      key: Key('milestone_card_$id'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(MilestonesPanel.inner, AppSpacing.md,
          MilestonesPanel.inner, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(MilestoneText.name(milestone),
                    style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              MilestoneStatusChip(
                  key: Key('milestone_status_$id'), status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          MilestoneBar(
            milestone: milestone,
            scale: scale,
            ageNow: controller.ageNow,
            achievedAge: at == null ? null : controller.ageOn(at),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(MilestoneText.line(milestone, at),
                    key: Key('milestone_line_$id'),
                    style: theme.textTheme.bodySmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (at == null)
                FilledButton.tonal(
                  key: Key('milestone_done_$id'),
                  onPressed: onRecord,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(64, AppSpacing.minTouchTarget)),
                  child: Text("Milestone_done".tr),
                )
              else
                TextButton(
                  key: Key('milestone_edit_$id'),
                  onPressed: onRecord,
                  style: TextButton.styleFrom(
                      minimumSize: const Size(64, AppSpacing.minTouchTarget)),
                  child: Text("Milestone_edit".tr),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
