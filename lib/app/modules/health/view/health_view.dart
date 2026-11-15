import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart'
    show pluralCategory;
import 'package:baby_vax/app/modules/home/widgets/quick_actions.dart';

import '../controller/health_controller.dart';
import '../model/health_entry.dart';
import '../widgets/health_entry_sheet.dart';
import '../widgets/health_labels.dart';
import '../widgets/health_profile_sheet.dart';
import '../widgets/temperature_chart.dart';

/// The Health tab: the days after a vaccine, a quick way to log a
/// temperature, signs, a medicine or a note, the latest temperature on a
/// 72-hour chart, the last medicine given, the log by day, the health
/// profile, and WHO's "when to get medical help".
class HealthView extends GetView<HealthController> {
  const HealthView({super.key});

  /// "3 hours ago", with the CLDR plural form of the current language.
  static String ago(DateTime then, DateTime now) {
    final Duration d = now.difference(then);
    if (d.inMinutes < 1) return "Health_ago_now".tr;
    final (String base, int n) = d.inMinutes < 60
        ? ('Health_ago_minutes', d.inMinutes)
        : d.inHours < 48
            ? ('Health_ago_hours', d.inHours)
            : ('Health_ago_days', d.inDays);
    String key =
        '${base}_${pluralCategory(n, Get.locale?.languageCode ?? 'en')}';
    if (key.tr == key) key = '${base}_other';
    return key.trParams(<String, String>{'count': '$n'});
  }

  /// "Today", "Yesterday" or the date.
  static String dayLabel(DateTime day, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (day == today) return "Health_today".tr;
    if (day == today.subtract(const Duration(days: 1))) {
      return "Health_yesterday".tr;
    }
    return AppDateFormat.date(day);
  }

  static void openGuide() => Get.toNamed(AppRoutes.healthGuide);

  Future<void> _add(HealthEntryKind kind, {String? doseId}) async {
    final HealthSheetResult? r = await HealthEntrySheet.show(
      kind: kind,
      now: controller.now,
      birthDate: controller.birthDate,
      doseId: doseId,
      onLearnMore: openGuide,
    );
    if (r is SaveHealthEntry) await controller.saveEntry(r.entry);
  }

  Future<void> _edit(HealthEntry e) async {
    final HealthSheetResult? r = await HealthEntrySheet.show(
      kind: e.kind,
      now: controller.now,
      initial: e,
      birthDate: controller.birthDate,
      onLearnMore: openGuide,
    );
    switch (r) {
      case SaveHealthEntry(:final HealthEntry entry):
        await controller.saveEntry(entry);
      case DeleteHealthEntry():
        final Completer<bool> yes = Completer<bool>();
        await AppConstant.alertService.showAlert(AlertModel.attention(
          message: "Health_delete_confirm".tr,
          yesAction: () => yes.complete(true),
          noAction: () => yes.complete(false),
        ));
        if (!yes.isCompleted) yes.complete(false);
        if (await yes.future) await controller.deleteEntry(e);
      case null:
        break;
    }
  }

  Future<void> _editProfile() async {
    final UserModel? current = controller.profile;
    if (current == null) return;
    final UserModel? updated = await HealthProfileSheet.show(current);
    if (updated == null) return;
    if (await controller.saveProfile(updated)) {
      AppSnackbar.success("Health_profile_saved".tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const AppLoading(showHero: true);
      if (controller.loadError.value != null && controller.items.isEmpty) {
        return AppErrorState(
            message: controller.loadError.value, onRetry: controller.fetch);
      }
      return RefreshIndicator(
        onRefresh: controller.fetch,
        child: _content(context),
      );
    });
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = controller.now;
    final MedicalDatesModel? dose = controller.recentDose;
    final HealthEntry? latest = controller.latestTemperature;
    final List<HealthEntry> chart = controller.recentTemperatures;
    final HealthEntry? medicine = controller.lastMedicine;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
      children: <Widget>[
        if (controller.actionError.value != null) ...<Widget>[
          AppBanner(
              tone: AppBannerTone.error,
              message: controller.actionError.value!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controller.savedOffline.value) ...<Widget>[
          AppBanner(
              key: const Key('health_saved_offline'),
              icon: Icons.cloud_off_rounded,
              message: "saved_offline_msg".tr),
          const SizedBox(height: AppSpacing.md),
        ],
        if (dose != null) ...<Widget>[
          _AfterVaccineCard(
            dose: dose,
            day: controller.dayAfter(dose),
            onTemperature: () =>
                _add(HealthEntryKind.temperature, doseId: dose.id),
            onSigns: () => _add(HealthEntryKind.symptoms, doseId: dose.id),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text("Health_intro".tr,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        AppSectionHeader(title: "Health_add_section".tr),
        for (final List<HealthEntryKind> row in <List<HealthEntryKind>>[
          <HealthEntryKind>[
            HealthEntryKind.temperature,
            HealthEntryKind.symptoms
          ],
          <HealthEntryKind>[HealthEntryKind.medicine, HealthEntryKind.note],
        ]) ...<Widget>[
          QuickActions(actions: <QuickAction>[
            for (final HealthEntryKind k in row)
              QuickAction(
                key: Key('health_add_${k.name}'),
                icon: HealthLabels.icon(k),
                label: HealthLabels.kind(k),
                onTap: () => _add(k),
              ),
          ]),
          const SizedBox(height: AppSpacing.md),
        ],
        if (latest != null) ...<Widget>[
          AppSectionHeader(title: "Health_temperature_section".tr),
          AppCard(
            key: const Key('health_latest_temp'),
            onTap: () => _edit(latest),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(HealthLabels.temperature(latest.tempC!),
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        <String>[
                          if (latest.method != null)
                            HealthLabels.method(latest.method!),
                          ago(latest.at, now),
                        ].join(' · '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                CareMessage(
                    level: controller.careLevelOf(latest),
                    onLearnMore: openGuide),
                if (chart.length >= 2) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text("Health_chart_title".tr,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  TemperatureChart(readings: chart, now: now),
                ],
              ],
            ),
          ),
        ],
        if (medicine != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppListGroup(children: <Widget>[
            AppListRow(
              key: const Key('health_last_medicine'),
              icon: Icons.medication_outlined,
              title: "Health_last_medicine".trParams(<String, String>{
                'name': bidiIsolate(medicine.medicine ?? ''),
              }),
              subtitle: <String>[
                ago(medicine.at, now),
                if (medicine.amount != null) bidiIsolate(medicine.amount!),
              ].join(' · '),
              onTap: () => _edit(medicine),
            ),
          ]),
        ],
        AppSectionHeader(title: "Health_log_section".tr),
        if (controller.items.isEmpty)
          AppEmptyState(
            key: const Key('health_empty'),
            scrollable: false,
            icon: Icons.monitor_heart_outlined,
            title: "Health_empty_title".tr,
            message: "Health_empty_body".tr,
          )
        else
          for (final (DateTime day, List<HealthEntry> entries)
              in controller.byDay) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Text(dayLabel(day, now),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            for (final HealthEntry e in entries) ...<Widget>[
              _EntryTile(
                  entry: e,
                  level: controller.careLevelOf(e),
                  onTap: () => _edit(e)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        AppSectionHeader(
          title: "Health_profile_title".tr,
          actionLabel: "Health_profile_edit".tr,
          onAction: _editProfile,
        ),
        _ProfileCard(user: controller.profile, onEdit: _editProfile),
        const SizedBox(height: AppSpacing.md),
        AppListGroup(children: <Widget>[
          AppListRow(
            key: const Key('health_open_guide'),
            icon: Icons.emergency_outlined,
            title: "Health_guide_title".tr,
            subtitle: "Health_guide_row_hint".tr,
            onTap: openGuide,
          ),
        ]),
        const SizedBox(height: AppSpacing.xxl),
        const MedicalDisclaimer(compact: true),
      ],
    );
  }
}

/// "After (vaccine) · day N", WHO's word on what is usual, and two ways to
/// log how the baby is.
class _AfterVaccineCard extends StatelessWidget {
  const _AfterVaccineCard({
    required this.dose,
    required this.day,
    required this.onTemperature,
    required this.onSigns,
  });

  final MedicalDatesModel dose;
  final int day;
  final VoidCallback onTemperature;
  final VoidCallback onSigns;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return AppCard(
      key: const Key('health_after_vaccine'),
      level: AppCardLevel.raised,
      color: scheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconBadge(
                icon: Icons.vaccines_outlined,
                background: scheme.surface,
                foreground: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Health_after_vaccine_title".trParams(<String, String>{
                        'vaccine': bidiIsolate(dose.displayName),
                      }),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: scheme.onPrimaryContainer),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Health_after_vaccine_day"
                          .trParams(<String, String>{'day': '$day'}),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text("Health_after_vaccine_body".tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              AppButton(
                key: const Key('health_after_temperature'),
                text: "Health_add_temperature".tr,
                icon: Icons.thermostat_rounded,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: onTemperature,
              ),
              AppButton(
                key: const Key('health_after_signs'),
                text: "Health_add_symptoms".tr,
                icon: Icons.sick_outlined,
                variant: AppButtonVariant.secondary,
                expand: false,
                onPressed: onSigns,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One entry in the log: what, when, the note, and WHO's message for it
/// as an icon and words (never colour alone).
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.level,
    required this.onTap,
  });

  final HealthEntry entry;
  final CareLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String summary = HealthLabels.summary(entry);
    final String? flag = switch (level) {
      CareLevel.urgent => "Health_flag_urgent".tr,
      CareLevel.seeHealthWorker => "Health_flag_see".tr,
      CareLevel.none => null,
    };
    return AppCard(
      key: Key('health_entry_${entry.id}'),
      onTap: onTap,
      semanticLabel: <String>[
        HealthLabels.kind(entry.kind),
        AppDateFormat.time(entry.at),
        summary,
        if (flag != null) flag,
        if (entry.kind != HealthEntryKind.note && entry.note != null)
          entry.note!,
      ].join('. '),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconBadge(icon: HealthLabels.icon(entry.kind), size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    '${AppDateFormat.time(entry.at)} · '
                    '${HealthLabels.kind(entry.kind)}',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                Text(summary,
                    style: theme.textTheme.bodyLarge,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                if (entry.kind != HealthEntryKind.note && entry.note != null)
                  Text(bidiIsolate(entry.note!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                if (flag != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Icon(
                          level == CareLevel.urgent
                              ? Icons.emergency_rounded
                              : Icons.warning_amber_rounded,
                          size: 16,
                          color: level == CareLevel.urgent
                              ? scheme.error
                              : scheme.secondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(flag,
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: level == CareLevel.urgent
                                    ? scheme.error
                                    : scheme.onSurface)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The health profile, or an invitation to fill it in.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onEdit});

  final UserModel? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final UserModel? u = user;
    if (u == null || !u.hasHealthProfile) {
      return AppCard(
        key: const Key('health_profile_empty'),
        onTap: onEdit,
        semanticLabel: "Health_profile_empty".tr,
        child: Row(
          children: <Widget>[
            const AppIconBadge(icon: Icons.badge_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Text("Health_profile_empty".tr,
                    style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }
    return AppListGroup(children: <Widget>[
      for (final (String key, String? value, IconData icon)
          in <(String, String?, IconData)>[
        ("Health_blood_type", u.bloodType, Icons.bloodtype_outlined),
        ("Health_allergies", u.allergies, Icons.no_food_outlined),
        ("Health_conditions", u.conditions, Icons.healing_outlined),
        ("Health_emergency", u.emergencyContact, Icons.call_outlined),
      ])
        if (value != null)
          AppListRow(
            key: Key('health_profile_$key'),
            icon: icon,
            title: key.tr,
            subtitle: bidiIsolate(value),
            onTap: onEdit,
          ),
    ]);
  }
}
