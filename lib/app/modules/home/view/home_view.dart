import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/modules/home/widgets/notifications_off_banner.dart';
import 'package:baby_vax/app/modules/home/widgets/quick_actions.dart';

import '../controller/home_controller.dart';

/// Home: the next dose first, then how far along the schedule is, then the
/// latest measurements, then the profile.
///
/// v1.0 led with a profile card (name and email) and put the next dose
/// last, below the fold on a small phone.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (_) => RefreshIndicator(
        onRefresh: () async => controller.fetchUserData(),
        child: Obx(() => _content(context, controller.summary)),
      ),
      onLoading: const AppLoading(showHero: true, itemCount: 3),
      onError: (String? error) => AppErrorState(
        message: error,
        onRetry: controller.fetchUserData,
      ),
      onEmpty: AppEmptyState(
        icon: Icons.person_search_outlined,
        title: "HomeView_no_profile_title".tr,
        message: "HomeView_no_profile_body".tr,
        actionLabel: "retry_label".tr,
        onAction: controller.fetchUserData,
      ),
    );
  }

  Widget _content(BuildContext context, ScheduleSummary summary) {
    final ThemeData theme = Theme.of(context);
    final UserModel? user = controller.userDetails.value;
    final String name = (user?.name ?? '').trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
      children: <Widget>[
        Text("HomeView_overline".tr,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Semantics(
          header: true,
          child: Text(
            name.isEmpty ? "Reminder_default_child_name".tr : bidiIsolate(name),
            style: theme.textTheme.headlineMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (controller.notificationsOff.value) ...<Widget>[
          NotificationsOffBanner(
              onOpenSettings: controller.openNotificationSettings),
          const SizedBox(height: AppSpacing.lg),
        ],
        _HeroCard(
          summary: summary,
          onOpen: controller.openDose,
          onSchedule: controller.openSchedule,
        ),
        const SizedBox(height: AppSpacing.md),
        _ProgressCard(summary: summary, onSchedule: controller.openSchedule),
        AppSectionHeader(title: "HomeView_quick_actions".tr),
        QuickActions(actions: <QuickAction>[
          QuickAction(
            key: const Key('home_action_card'),
            icon: Icons.picture_as_pdf_rounded,
            label: "Card_export".tr,
            onTap: controller.openVaccinationCard,
          ),
          QuickAction(
            key: const Key('home_action_growth'),
            icon: Icons.show_chart_rounded,
            label: "Growth_title".tr,
            onTap: controller.openGrowth,
          ),
        ]),
        AppSectionHeader(
          title: "HomeView_measurements_title".tr,
          actionLabel: "Growth_title".tr,
          onAction: controller.openGrowth,
        ),
        _Measurements(user: user, onTap: controller.openGrowth),
        AppSectionHeader(title: "HomeView_profile_title".tr),
        AppListGroup(children: <Widget>[
          AppListRow(
            key: const Key('home_profile_row'),
            icon: Icons.child_care_rounded,
            title: name.isEmpty ? '—' : bidiIsolate(name),
            subtitle: bidiIsolate(user?.email ?? ''),
            onTap: controller.openEditProfile,
          ),
        ]),
        const SizedBox(height: AppSpacing.xxl),
        const MedicalDisclaimer(compact: true),
      ],
    );
  }
}

/// The one dose that needs attention next, or "all caught up".
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.summary,
    required this.onOpen,
    required this.onSchedule,
  });

  final ScheduleSummary summary;
  final ValueChanged<MedicalDatesModel> onOpen;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final MedicalDatesModel? dose = summary.hero;

    if (dose == null) {
      return AppCard(
        key: const Key('home_hero_done'),
        level: AppCardLevel.raised,
        borderRadius: AppRadius.xlAll,
        color: scheme.primaryContainer,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: <Widget>[
            Icon(Icons.verified_rounded,
                size: 40, color: scheme.onPrimaryContainer),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                      summary.total == 0
                          ? "HomeView_no_schedule_title".tr
                          : "HomeView_all_done_title".tr,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: scheme.onPrimaryContainer)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                      summary.total == 0
                          ? "HomeView_no_schedule_body".tr
                          : "HomeView_all_done_body".tr,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final DoseDisplayStatus status =
        VaccineStatePolicy.displayStatus(dose, summary.now);
    final bool overdue = status == DoseDisplayStatus.overdue;
    final String? countdown = doseCountdown(dose, summary.now);
    final String date = AppDateFormat.date(dose.date);

    return AppCard(
      key: const Key('home_hero'),
      level: AppCardLevel.raised,
      borderRadius: AppRadius.xlAll,
      padding: const EdgeInsets.all(AppSpacing.xl),
      onTap: () => onOpen(dose),
      semanticLabel: <String>[
        overdue ? "HomeView_overdue_dose".tr : "HomeView_next_dose".tr,
        dose.displayName,
        status.translationKey.tr,
        date,
        if (countdown != null) countdown,
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconBadge(
                icon: Icons.vaccines_rounded,
                background:
                    overdue ? scheme.errorContainer : scheme.primaryContainer,
                foreground: overdue
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  overdue
                      ? "HomeView_overdue_dose".tr
                      : "HomeView_next_dose".tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: overdue ? scheme.error : scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            bidiIsolate(dose.displayName),
            style: theme.textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppStatusChip(status: status),
              Text(date, style: theme.textTheme.bodyMedium),
            ],
          ),
          if (countdown != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(countdown,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: scheme.primary)),
          ],
          if (overdue && summary.overdue > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              "HomeView_more_overdue".trParams(
                  <String, String>{'count': '${summary.overdue - 1}'}),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('home_hero_open'),
            text: "HomeView_open_dose".tr,
            onPressed: () => onOpen(dose),
          ),
        ],
      ),
    );
  }
}

/// "7 of 10 doses given", calmly.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary, required this.onSchedule});

  final ScheduleSummary summary;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      key: const Key('home_progress'),
      onTap: onSchedule,
      child: Row(
        children: <Widget>[
          AppProgressRing(
              done: summary.completed, total: summary.countable, size: 72),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("HomeView_progress_title".tr,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "HomeView_progress_body".trParams(<String, String>{
                    'done': '${summary.completed}',
                    'total': '${summary.countable}',
                  }),
                  style: theme.textTheme.bodySmall,
                ),
                if (summary.overdue > 0 || summary.skipped > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      if (summary.overdue > 0)
                        _CountChip(
                            status: DoseDisplayStatus.overdue,
                            count: summary.overdue),
                      if (summary.skipped > 0)
                        _CountChip(
                            status: DoseDisplayStatus.skipped,
                            count: summary.skipped),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left_rounded
                : Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// A status with a count beside it: "Overdue 2". The number stands alone, so
/// no plural agreement is needed in Arabic.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.status, required this.count});

  final DoseDisplayStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final pair = AppStatusColors.of(context).forStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
          color: pair.background, borderRadius: AppRadius.pillAll),
      child: Text('${status.translationKey.tr}: $count',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: pair.foreground)),
    );
  }
}

/// Weight, height, head circumference and haemoglobin, two per row. The
/// rows grow with the text scale instead of clipping (v1.0 fixed the tile
/// aspect ratio).
class _Measurements extends StatelessWidget {
  const _Measurements({required this.user, required this.onTap});

  final UserModel? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String v(String? s) =>
        (s ?? '').trim().isEmpty ? AppMetricTile.empty : s!.trim();
    final List<Widget> tiles = <Widget>[
      AppMetricTile(
          icon: Icons.monitor_weight_outlined,
          label: "weight_label".tr,
          value: v(user?.weight),
          unit: "unit_kg".tr,
          onTap: onTap),
      AppMetricTile(
          icon: Icons.straighten_rounded,
          label: "height_label".tr,
          value: v(user?.height),
          unit: "unit_cm".tr,
          onTap: onTap),
      AppMetricTile(
          icon: Icons.face_rounded,
          label: "head_size_label".tr,
          value: v(user?.headSize),
          unit: "unit_cm".tr,
          onTap: onTap),
      AppMetricTile(
          icon: Icons.bloodtype_outlined,
          label: "blood_percentage_label".tr,
          value: v(user?.bloodPercentage),
          unit: "unit_g_dl".tr,
          onTap: onTap),
    ];
    return Column(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: tiles[i]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
