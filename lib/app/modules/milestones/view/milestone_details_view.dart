import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';

import '../controller/milestones_controller.dart';
import '../model/milestone_record.dart';
import '../widgets/milestone_bar.dart';
import 'milestones_panel.dart';

/// One milestone: its bar, the usual range, the status, what counts, and
/// the parent's note for the doctor visit. Information only: no diagnosis
/// wording, no warnings, no notifications.
class MilestoneDetailsView extends GetView<MilestonesController> {
  const MilestoneDetailsView({super.key, this.milestoneId});

  /// The milestone's id; the route's argument when null.
  final String? milestoneId;

  MotorMilestone get milestone =>
      MotorMilestone.fromId(milestoneId ?? Get.arguments as String?) ??
      MotorMilestone.sitting;

  @override
  Widget build(BuildContext context) {
    final MotorMilestone m = milestone;
    final MilestoneActions actions = MilestoneActions(controller);
    return Scaffold(
      appBar: CustomAppBar(title: MilestoneText.name(m)),
      body: Obx(() {
        final ThemeData theme = Theme.of(context);
        final MilestoneRecord? r = controller.recordOf(m);
        final DateTime? at = r?.achievedAt;
        final MilestoneStatus status = controller.statusOf(m);
        final double? age = controller.ageNow;
        final MilestoneScale scale = MilestoneScale.forAge(age);
        return ListView(
          key: const Key('milestone_details'),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
          children: <Widget>[
            if (controller.actionError.value != null) ...<Widget>[
              AppBanner(
                  tone: AppBannerTone.error,
                  message: controller.actionError.value!),
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(
              key: const Key('milestone_details_card'),
              padding: const EdgeInsets.all(MilestonesPanel.inner),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MilestoneStatusChip(
                        key: const Key('milestone_details_status'),
                        status: status),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MilestoneScaleHeader(scale: scale),
                  const SizedBox(height: AppSpacing.xs),
                  MilestoneBar(
                    milestone: m,
                    scale: scale,
                    ageNow: age,
                    achievedAge: at == null ? null : controller.ageOn(at),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(MilestoneText.range(m),
                      key: const Key('milestone_details_range'),
                      style: theme.textTheme.bodyMedium),
                  if (at != null)
                    Text(MilestoneText.line(m, at),
                        key: const Key('milestone_details_achieved'),
                        style: theme.textTheme.bodyMedium),
                  if (m.optional && at == null)
                    Text("Milestone_crawling_skip".tr,
                        style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.md),
                  const MilestonesLegend(),
                ],
              ),
            ),
            if (status == MilestoneStatus.pastWindow) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppBanner(
                key: const Key('milestone_details_info'),
                tone: AppBannerTone.info,
                title: "Milestone_info_title".tr,
                message: "Milestone_info_body".tr,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(title: "Milestone_what_counts".tr),
            Text(MilestoneText.criteria(m),
                key: const Key('milestone_details_criteria'),
                style: theme.textTheme.bodyMedium),
            if (r?.note != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppSectionHeader(title: "Milestone_note_title".tr),
              Text(bidiIsolate(r!.note!),
                  key: const Key('milestone_details_note_text'),
                  style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (at == null)
              AppButton(
                key: const Key('milestone_details_record'),
                text: "Milestone_record_date".tr,
                icon: Icons.check_rounded,
                onPressed: () => actions.record(m),
              )
            else
              AppButton(
                key: const Key('milestone_details_edit'),
                text: "Milestone_edit".tr,
                icon: Icons.edit_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => actions.record(m),
              ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                key: const Key('milestone_details_note'),
                onPressed: () => actions.note(m),
                style: TextButton.styleFrom(
                    minimumSize: const Size(64, AppSpacing.minTouchTarget)),
                child:
                    Text("Milestone_add_note".tr, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("Milestone_source".tr,
                key: const Key('milestone_details_source'),
                style: theme.textTheme.bodySmall),
          ],
        );
      }),
    );
  }
}
