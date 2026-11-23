import 'package:baby_vax/app/core/imports/import_manger.dart';

/// "When to get medical help": WHO's danger signs and "return
/// immediately" signs, what is normal after a vaccine, and WHO's fever
/// figure. Every line comes from the sources in docs/THIRD_PARTY.md
/// ("WHO guidance used by the Health log"); the screen names them.
class HealthGuideView extends StatelessWidget {
  const HealthGuideView({super.key});

  /// Section title key, tone, icon, and the keys of its lines.
  static const List<(String, AppBannerTone, IconData, List<String>)> sections =
      <(String, AppBannerTone, IconData, List<String>)>[
    (
      "Health_guide_urgent_title",
      AppBannerTone.error,
      Icons.emergency_rounded,
      <String>[
        "Health_guide_urgent_1",
        "Health_guide_urgent_2",
        "Health_guide_urgent_3",
        "Health_guide_urgent_4",
      ]
    ),
    (
      "Health_guide_young_title",
      AppBannerTone.error,
      Icons.child_care_rounded,
      <String>[
        "Health_guide_young_1",
        "Health_guide_young_2",
        "Health_guide_young_3",
        "Health_guide_young_4",
        "Health_guide_young_5",
        "Health_guide_young_6",
      ]
    ),
    (
      "Health_guide_see_title",
      AppBannerTone.warning,
      Icons.local_hospital_outlined,
      <String>[
        "Health_guide_see_1",
        "Health_guide_see_2",
        "Health_guide_see_3",
        "Health_guide_see_4",
      ]
    ),
    (
      "Health_guide_vaccine_title",
      AppBannerTone.info,
      Icons.vaccines_outlined,
      <String>[
        "Health_after_vaccine_body",
        "Health_guide_vaccine_2",
      ]
    ),
    (
      "Health_guide_fever_title",
      AppBannerTone.info,
      Icons.thermostat_rounded,
      <String>[
        "Health_guide_fever_1",
        "Health_guide_fever_2",
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Scaffold(
      appBar: CustomAppBar(title: "Health_guide_title".tr),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
        children: <Widget>[
          Text("Health_guide_intro".tr,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          for (final (
                String title,
                AppBannerTone tone,
                IconData icon,
                List<String> lines
              ) in sections) ...<Widget>[
            AppSectionHeader(title: title.tr),
            AppCard(
              key: Key('health_guide_$title'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final String l in lines)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(icon,
                                size: 18,
                                color: switch (tone) {
                                  AppBannerTone.error => scheme.error,
                                  AppBannerTone.warning =>
                                      AppStatusColors.of(context)
                                          .warningForeground,
                                  _ => scheme.primary,
                                }),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: Text(l.tr,
                                  style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text("Health_guide_source".tr,
              key: const Key('health_guide_source'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          const MedicalDisclaimer(),
        ],
      ),
    );
  }
}
