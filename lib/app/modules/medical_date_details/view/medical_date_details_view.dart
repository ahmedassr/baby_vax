import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/modules/medical_date_details/widgets/medical_date_actions.dart';

/// One dose. The vaccine name is the title (two lines, as in v1.0's fix);
/// the actions stay pinned at the bottom.
class MedicalDateDetailsView extends GetView<MedicalDateDetailsController> {
  const MedicalDateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final MedicalDatesModel? dose = controller.dose.value;
      return Scaffold(
        appBar: CustomAppBar(
          title: dose == null
              ? "MedicalDateDetailsView_title".tr
              : bidiIsolate(dose.displayName),
          titleMaxLines: 2,
        ),
        body: dose == null
            ? AppEmptyState(
                icon: Icons.event_busy_rounded,
                title:
                    "MedicalDateDetailsController_missing_medical_dates_msg".tr,
                actionLabel: "back_label".tr,
                onAction: Get.back,
              )
            : _body(context, dose),
        bottomNavigationBar: dose == null ? null : _actions(context),
      );
    });
  }

  Widget _body(BuildContext context, MedicalDatesModel dose) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = controller.now;
    final DoseDisplayStatus status =
        VaccineStatePolicy.displayStatus(dose, now);
    final String? countdown = doseCountdown(dose, now);
    final AgeGroup group = groupByAge(<MedicalDatesModel>[dose]).first;

    return ListView(
      padding: AppSpacing.screenVertical,
      children: <Widget>[
        AppCard(
          level: AppCardLevel.raised,
          borderRadius: AppRadius.xlAll,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const AppIconBadge(icon: Icons.vaccines_rounded, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppStatusChip(status: status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Fact(
                icon: Icons.event_rounded,
                label: "MedicalDateDetails_scheduled_label".tr,
                value: AppDateFormat.date(dose.date),
              ),
              if (group.months != null)
                _Fact(
                  icon: Icons.child_care_rounded,
                  label: "MedicalDateDetails_age_label".tr,
                  value: group.label,
                ),
              if (countdown != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(countdown,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
              ],
            ],
          ),
        ),
        Obx(() => controller.errorMessage.value == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: AppBanner(
                  key: const Key('details_error'),
                  tone: AppBannerTone.error,
                  message: controller.errorMessage.value!,
                ),
              )),
        Obx(() => controller.savedOffline.value
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: AppBanner(
                  key: const Key('details_saved_offline'),
                  tone: AppBannerTone.info,
                  icon: Icons.cloud_off_rounded,
                  message: "saved_offline_msg".tr,
                ),
              )
            : const SizedBox.shrink()),
        if (controller.canEditRecord) _RecordSection(controller: controller),
        if (dose.displayDescription.isNotEmpty) ...<Widget>[
          AppSectionHeader(title: "MedicalDateDetails_about_title".tr),
          AppCard(
            child: SelectableText(bidiIsolate(dose.displayDescription),
                style: theme.textTheme.bodyLarge),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const MedicalDisclaimer(),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Obx(() {
            // Read so this Obx rebuilds when the dose changes.
            controller.dose.value;
            return MedicalDateActions(
              canMarkCompleted: controller.canMarkCompleted,
              canMarkSkipped: controller.canMarkSkipped,
              canUndo: controller.canUndo,
              busy: controller.isSaving.value,
              onMarkCompleted: controller.onMarkCompleted,
              onMarkSkipped: controller.onMarkSkipped,
              onUndo: controller.onUndo,
            );
          }),
        ),
      ),
    );
  }
}

/// What was recorded when the dose was given, with Edit / Add details.
class _RecordSection extends StatelessWidget {
  const _RecordSection({required this.controller});

  final MedicalDateDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DoseRecord r = controller.dose.value!.record;
    final bool has = controller.hasRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: "Record_section_title".tr,
          actionLabel: has ? "Record_edit".tr : "Record_add_details".tr,
          onAction: controller.onEditRecord,
        ),
        AppCard(
          key: const Key('record_section'),
          child: has
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (r.givenDate != null)
                      _Fact(
                          icon: Icons.event_available_rounded,
                          label: "Record_given_date".tr,
                          value: AppDateFormat.date(r.givenDate!)),
                    if (r.clinic != null)
                      _Fact(
                          icon: Icons.local_hospital_outlined,
                          label: "Record_clinic".tr,
                          value: bidiIsolate(r.clinic!)),
                    if (r.lot != null)
                      _Fact(
                          icon: Icons.qr_code_2_rounded,
                          label: "Record_lot".tr,
                          value: bidiIsolate(r.lot!)),
                    if (r.note != null)
                      _Fact(
                          icon: Icons.notes_rounded,
                          label: "Record_note".tr,
                          value: bidiIsolate(r.note!)),
                  ],
                )
              : Text("Record_none".tr, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// An icon, a small label and a value on one line, wrapping when long.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(TextSpan(children: <InlineSpan>[
                TextSpan(
                    text: '$label: ',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                TextSpan(text: value, style: theme.textTheme.titleSmall),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}
