import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';

import '../controller/reminders_controller.dart';
import '../model/reminder_model.dart';
import '../widgets/reminder_sheet.dart';

/// The parent's own reminders and appointments.
class RemindersView extends GetView<RemindersController> {
  const RemindersView({super.key});

  /// Opens the add sheet and saves the result. Shared with the schedule
  /// screen's FAB.
  static Future<void> addFlow(RemindersController c) async {
    final ReminderSheetResult? r = await ReminderSheet.show(now: c.now);
    if (r is SaveReminder) await c.saveReminder(r.reminder);
  }

  Future<void> _edit(ReminderModel r) async {
    final ReminderSheetResult? out =
        await ReminderSheet.show(now: controller.now, initial: r);
    switch (out) {
      case SaveReminder(:final ReminderModel reminder):
        await controller.saveReminder(reminder);
      case DeleteReminder():
        final Completer<bool> yes = Completer<bool>();
        await AppConstant.alertService.showAlert(AlertModel.attention(
          message: "Reminders_delete_confirm".tr,
          yesAction: () => yes.complete(true),
          noAction: () => yes.complete(false),
        ));
        if (!yes.isCompleted) yes.complete(false);
        if (await yes.future) await controller.deleteReminder(r);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.onOpenAdd ??= () => addFlow(controller);
    return Scaffold(
      appBar: CustomAppBar(title: "Reminders_title".tr),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('reminders_add'),
        onPressed: () => addFlow(controller),
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text("Reminders_add".tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoading();
        if (controller.loadError.value != null && controller.items.isEmpty) {
          return AppErrorState(
              message: controller.loadError.value, onRetry: controller.fetch);
        }
        final List<ReminderModel> list = controller.sorted;
        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 112),
            children: <Widget>[
              Text("Reminders_hint".tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              if (controller.actionError.value != null) ...<Widget>[
                AppBanner(
                    tone: AppBannerTone.error,
                    message: controller.actionError.value!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (controller.savedOffline.value) ...<Widget>[
                AppBanner(
                    key: const Key('reminders_saved_offline'),
                    icon: Icons.cloud_off_rounded,
                    message: "saved_offline_msg".tr),
                const SizedBox(height: AppSpacing.md),
              ],
              if (list.isEmpty)
                AppEmptyState(
                  scrollable: false,
                  icon: Icons.alarm_add_rounded,
                  title: "Reminders_empty_title".tr,
                  message: "Reminders_empty_body".tr,
                  actionLabel: "Reminders_add".tr,
                  onAction: () => addFlow(controller),
                )
              else
                for (final ReminderModel r in list) ...<Widget>[
                  _ReminderTile(
                    reminder: r,
                    now: controller.now,
                    onTap: () => _edit(r),
                    onToggle: (bool v) => controller.setEnabled(r, v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        );
      }),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.now,
    required this.onTap,
    required this.onToggle,
  });

  final ReminderModel reminder;
  final DateTime now;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? next = reminder.nextAfter(now);
    final String when = next == null
        ? "Reminders_past".trParams(
            <String, String>{'date': AppDateFormat.dateTime(reminder.dateTime)})
        : AppDateFormat.dateTime(next);
    final String repeat = switch (reminder.repeat) {
      ReminderRepeat.none => '',
      ReminderRepeat.daily => "Reminders_repeat_daily".tr,
      ReminderRepeat.weekly => "Reminders_repeat_weekly".tr,
      ReminderRepeat.monthly => "Reminders_repeat_monthly".tr,
    };
    final bool active = reminder.enabled && next != null;

    return AppCard(
      padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.xs,
          top: AppSpacing.md,
          bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.mdAll,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
                child: Row(
                  children: <Widget>[
                    AppIconBadge(
                      icon: reminder.repeat == ReminderRepeat.none
                          ? Icons.event_rounded
                          : Icons.repeat_rounded,
                      background: active
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      foreground: active
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(bidiIsolate(reminder.title),
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          Text(repeat.isEmpty ? when : '$when · $repeat',
                              style: theme.textTheme.bodySmall),
                          if (reminder.note != null)
                            Text(bidiIsolate(reminder.note!),
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            label: "Reminders_toggle_label"
                .trParams(<String, String>{'title': reminder.title}),
            child: Switch(
              key: Key('reminder_switch_${reminder.id}'),
              value: reminder.enabled,
              onChanged: next == null ? null : onToggle,
            ),
          ),
        ],
      ),
    );
  }
}
