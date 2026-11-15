import 'dart:async';

import 'package:flutter/services.dart';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/service/phone_dialer.dart';
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
    final DateTime now = controller.now;
    final MedicalDatesModel? dose = controller.recentDose;
    final HealthEntry? latest = controller.latestTemperature;
    final HealthEntry? medicine = controller.lastMedicine;
    final UserModel? profile = controller.profile;

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
        if (dose != null)
          _AfterVaccineCard(
            dose: dose,
            day: controller.dayAfter(dose),
            onTemperature: () =>
                _add(HealthEntryKind.temperature, doseId: dose.id),
            onSigns: () => _add(HealthEntryKind.symptoms, doseId: dose.id),
          ),

        // ---- log something -------------------------------------------
        AppSectionHeader(
            title: "Health_add_section".tr, subtitle: "Health_intro".tr),
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

        // ---- the last 72 hours ---------------------------------------
        if (latest != null || medicine != null) ...<Widget>[
          AppSectionHeader(title: "Health_chart_title".tr),
          _RecentCard(
            latest: latest,
            level: latest == null
                ? CareLevel.none
                : controller.careLevelOf(latest),
            chart: controller.recentTemperatures,
            medicine: medicine,
            now: now,
            onEdit: _edit,
          ),
        ],

        // ---- the log -------------------------------------------------
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
          _HealthLog(
            days: controller.byDay,
            now: now,
            levelOf: controller.careLevelOf,
            onTap: _edit,
          ),

        // ---- medical ID ----------------------------------------------
        AppSectionHeader(
          title: "Health_profile_title".tr,
          actionLabel: profile?.hasHealthProfile ?? false
              ? "Health_profile_edit".tr
              : null,
          onAction: _editProfile,
        ),
        _MedicalIdCard(user: profile, onEdit: _editProfile),
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

/// "After (vaccine)", which of the three days this is, WHO's word on what
/// is usual, and two ways to log how the baby is.
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
    const int total = HealthController.afterVaccineDays;
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
                child: Text(
                  "Health_after_vaccine_title".trParams(<String, String>{
                    'vaccine': bidiIsolate(dose.displayName),
                  }),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Day 1, 2 or 3 of the three days the card is shown, as words and
          // as three segments.
          Semantics(
            excludeSemantics: true,
            label: "Health_after_vaccine_day"
                .trParams(<String, String>{'day': '$day', 'total': '$total'}),
            child: Row(
              children: <Widget>[
                for (int i = 1; i <= total; i++) ...<Widget>[
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= day
                            ? scheme.primary
                            : scheme.onPrimaryContainer.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillAll,
                      ),
                    ),
                  ),
                  if (i < total) const SizedBox(width: AppSpacing.xs),
                ],
                const SizedBox(width: AppSpacing.md),
                Text(
                  "Health_after_vaccine_day".trParams(
                      <String, String>{'day': '$day', 'total': '$total'}),
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text("Health_after_vaccine_body".tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.lg),
          // Both buttons share the row; they stack when the labels need
          // more room (large text).
          LayoutBuilder(builder: (context, c) {
            final List<Widget> buttons = <Widget>[
              AppButton(
                key: const Key('health_after_temperature'),
                text: "Health_add_temperature".tr,
                icon: Icons.thermostat_rounded,
                onPressed: onTemperature,
              ),
              AppButton(
                key: const Key('health_after_signs'),
                text: "Health_add_symptoms".tr,
                icon: Icons.sick_outlined,
                variant: AppButtonVariant.outline,
                onPressed: onSigns,
              ),
            ];
            final bool side = c.maxWidth >= 280 &&
                MediaQuery.textScalerOf(context).scale(14) <= 15;
            return side
                ? Row(children: <Widget>[
                    Expanded(child: buttons[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: buttons[1]),
                  ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      buttons[0],
                      const SizedBox(height: AppSpacing.sm),
                      buttons[1],
                    ],
                  );
          }),
        ],
      ),
    );
  }
}

/// The last 72 hours in one card: the latest temperature, WHO's message
/// for it, the chart, and the last medicine given.
class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.latest,
    required this.level,
    required this.chart,
    required this.medicine,
    required this.now,
    required this.onEdit,
  });

  final HealthEntry? latest;
  final CareLevel level;
  final List<HealthEntry> chart;
  final HealthEntry? medicine;
  final DateTime now;
  final ValueChanged<HealthEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final HealthEntry? t = latest;
    final HealthEntry? m = medicine;
    return AppCard(
      key: const Key('health_recent'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (t != null)
            InkWell(
              key: const Key('health_latest_temp'),
              onTap: () => onEdit(t),
              child: Padding(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text("Health_temperature_section".tr,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Text(HealthLabels.temperature(t.tempC!),
                            style: theme.textTheme.displaySmall?.copyWith(
                                color: level == CareLevel.urgent
                                    ? scheme.error
                                    : scheme.onSurface)),
                        Text(
                          <String>[
                            if (t.method != null)
                              HealthLabels.method(t.method!),
                            HealthView.ago(t.at, now),
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (level != CareLevel.none) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      CareMessage(
                          level: level, onLearnMore: HealthView.openGuide),
                    ],
                    if (chart.length >= 2) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      TemperatureChart(readings: chart, now: now),
                    ],
                  ],
                ),
              ),
            ),
          if (t != null && m != null)
            const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          if (m != null)
            AppListRow(
              key: const Key('health_last_medicine'),
              icon: Icons.medication_outlined,
              title: "Health_last_medicine".trParams(<String, String>{
                'name': bidiIsolate(m.medicine ?? ''),
              }),
              subtitle: <String>[
                HealthView.ago(m.at, now),
                if (m.amount != null) bidiIsolate(m.amount!),
              ].join(' · '),
              onTap: () => onEdit(m),
            ),
        ],
      ),
    );
  }
}

/// The log by day, each day one card of entries. The three most recent
/// days are shown; the rest open with "Show all".
class _HealthLog extends StatefulWidget {
  const _HealthLog({
    required this.days,
    required this.now,
    required this.levelOf,
    required this.onTap,
  });

  final List<(DateTime, List<HealthEntry>)> days;
  final DateTime now;
  final CareLevel Function(HealthEntry) levelOf;
  final ValueChanged<HealthEntry> onTap;

  static const int recentDays = 3;

  @override
  State<_HealthLog> createState() => _HealthLogState();
}

class _HealthLogState extends State<_HealthLog> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int hidden = widget.days.length - _HealthLog.recentDays;
    final Iterable<(DateTime, List<HealthEntry>)> shown = _all || hidden <= 0
        ? widget.days
        : widget.days.take(_HealthLog.recentDays);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final (DateTime day, List<HealthEntry> entries)
            in shown) ...<Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xs,
                top: AppSpacing.sm,
                bottom: AppSpacing.sm),
            child: Semantics(
              header: true,
              child: Text(HealthView.dayLabel(day, widget.now),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < entries.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                        indent: AppSpacing.lg + 40 + AppSpacing.md,
                        endIndent: AppSpacing.lg),
                  _EntryRow(
                    entry: entries[i],
                    level: widget.levelOf(entries[i]),
                    onTap: () => widget.onTap(entries[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (hidden > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('health_log_toggle'),
              onPressed: () => setState(() => _all = !_all),
              icon: Icon(
                  _all ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(
                  _all ? "Health_log_show_less".tr : "Health_log_show_all".tr),
            ),
          ),
      ],
    );
  }
}

/// One entry: what (as the title), when and what kind, any note, and WHO's
/// message for it as an icon and words (never colour alone).
class _EntryRow extends StatelessWidget {
  const _EntryRow({
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
    final bool urgent = level == CareLevel.urgent;
    return Semantics(
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      label: <String>[
        HealthLabels.kind(entry.kind),
        AppDateFormat.time(entry.at),
        summary,
        if (flag != null) flag,
        if (entry.kind != HealthEntryKind.note && entry.note != null)
          entry.note!,
      ].join('. '),
      child: InkWell(
        key: Key('health_entry_${entry.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconBadge(
                icon: HealthLabels.icon(entry.kind),
                size: 40,
                background: urgent ? scheme.errorContainer : null,
                foreground: urgent ? scheme.onErrorContainer : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(summary,
                        style: theme.textTheme.bodyLarge,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                        '${AppDateFormat.time(entry.at)} · '
                        '${HealthLabels.kind(entry.kind)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    if (entry.kind != HealthEntryKind.note &&
                        entry.note != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(bidiIsolate(entry.note!),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    if (flag != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      _FlagPill(text: flag, urgent: urgent),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// WHO's flag on an entry as a small pill with an icon.
class _FlagPill extends StatelessWidget {
  const _FlagPill({required this.text, required this.urgent});

  final String text;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bg = urgent ? scheme.errorContainer : scheme.secondaryContainer;
    final Color fg =
        urgent ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(urgent ? Icons.emergency_rounded : Icons.warning_amber_rounded,
              size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(text,
                style: theme.textTheme.labelMedium?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// The health profile as a medical ID: blood type, allergies, conditions,
/// and the emergency contact with Call and Copy. Without a profile, an
/// invitation to fill it in.
class _MedicalIdCard extends StatelessWidget {
  const _MedicalIdCard({required this.user, required this.onEdit});

  final UserModel? user;
  final VoidCallback onEdit;

  Future<void> _call(String phone) async {
    if (!await PhoneDialer.dial(phone)) {
      AppSnackbar.error("Health_call_failed".tr);
    }
  }

  Future<void> _copy(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    AppSnackbar.success("Health_phone_copied".tr);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final UserModel? u = user;
    if (u == null || !u.hasHealthProfile) {
      return AppCard(
        key: const Key('health_profile_empty'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppIconBadge(icon: Icons.medical_information_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Text("Health_profile_empty".tr,
                        style: theme.textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('health_profile_add'),
              text: "Health_profile_add".tr,
              icon: Icons.add_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: onEdit,
            ),
          ],
        ),
      );
    }
    final EmergencyContact? c = u.emergencyContact;
    final List<(String, String?, IconData)> facts =
        <(String, String?, IconData)>[
      ("Health_allergies", u.allergies, Icons.no_food_outlined),
      ("Health_conditions", u.conditions, Icons.healing_outlined),
    ];
    return AppCard(
      key: const Key('health_medical_id'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Blood type, large, as on a medical ID.
          InkWell(
            key: const Key('health_profile_Health_blood_type'),
            onTap: onEdit,
            child: Padding(
              padding: AppSpacing.card,
              child: Row(
                children: <Widget>[
                  AppIconBadge(
                    icon: Icons.bloodtype_outlined,
                    background: scheme.errorContainer,
                    foreground: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text("Health_blood_type".tr,
                        style: theme.textTheme.titleSmall),
                  ),
                  Text(
                    u.bloodType == null
                        ? "Health_blood_unknown".tr
                        : bidiIsolate(u.bloodType!),
                    style: u.bloodType == null
                        ? theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)
                        : theme.textTheme.headlineSmall
                            ?.copyWith(color: scheme.error),
                  ),
                ],
              ),
            ),
          ),
          for (final (String key, String? value, IconData icon) in facts)
            if (value != null) ...<Widget>[
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              AppListRow(
                key: Key('health_profile_$key'),
                icon: icon,
                title: key.tr,
                subtitle: bidiIsolate(value),
                onTap: onEdit,
              ),
            ],
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          if (c == null)
            AppListRow(
              key: const Key('health_contact_add'),
              icon: Icons.contact_phone_outlined,
              title: "Health_emergency".tr,
              subtitle: "Health_contact_add".tr,
              onTap: onEdit,
            )
          else
            Padding(
              key: const Key('health_contact'),
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text("Health_emergency".tr,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(c.name.characters.first.toUpperCase(),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: scheme.onPrimaryContainer)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              c.relation == null
                                  ? bidiIsolate(c.name)
                                  : "Health_contact_with_relation"
                                      .trParams(<String, String>{
                                      'name': bidiIsolate(c.name),
                                      'relation':
                                          "Health_relation_${c.relation}".tr,
                                    }),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(bidiIsolate(c.phone),
                                key: const Key('health_contact_phone_text'),
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppButton(
                          key: const Key('health_contact_call'),
                          text: "Health_call".tr,
                          icon: Icons.call_rounded,
                          onPressed: () => _call(c.phone),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.outlined(
                        key: const Key('health_contact_copy'),
                        tooltip: "Health_copy_phone".tr,
                        constraints: const BoxConstraints(
                            minWidth: AppSpacing.minTouchTarget,
                            minHeight: AppSpacing.minTouchTarget),
                        onPressed: () => _copy(c.phone),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
