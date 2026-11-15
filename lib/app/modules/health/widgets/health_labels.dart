import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';

import '../model/health_entry.dart';

/// Labels and icons for the Health log, in the current language.
class HealthLabels {
  const HealthLabels._();

  /// The order signs are offered in: everyday ones first, WHO's danger
  /// signs last. (Storage uses [HealthSymptom.name], not this order.)
  static const List<HealthSymptom> symptomOrder = <HealthSymptom>[
    HealthSymptom.feelsHot,
    HealthSymptom.injectionSite,
    HealthSymptom.crying,
    HealthSymptom.feedingPoorly,
    HealthSymptom.vomiting,
    HealthSymptom.diarrhoea,
    HealthSymptom.cough,
    HealthSymptom.runnyNose,
    HealthSymptom.rash,
    HealthSymptom.fastBreathing,
    HealthSymptom.difficultBreathing,
    HealthSymptom.lessActive,
    HealthSymptom.feelsCold,
    HealthSymptom.yellowSkin,
    HealthSymptom.bloodInStool,
    HealthSymptom.vomitsEverything,
    HealthSymptom.unableToFeed,
    HealthSymptom.lethargic,
    HealthSymptom.convulsions,
  ];

  static String symptom(HealthSymptom s) => "Health_symptom_${s.name}".tr;

  static String method(TemperatureMethod m) => "Health_method_${m.name}".tr;

  static String kind(HealthEntryKind k) => "Health_kind_${k.name}".tr;

  static IconData icon(HealthEntryKind k) => switch (k) {
        HealthEntryKind.temperature => Icons.thermostat_rounded,
        HealthEntryKind.symptoms => Icons.sick_outlined,
        HealthEntryKind.medicine => Icons.medication_outlined,
        HealthEntryKind.note => Icons.sticky_note_2_outlined,
      };

  /// "38.4 °C", always with Western digits and one decimal, kept left to
  /// right inside Arabic text (unisolated it reads "C° 38.4").
  static String temperature(double c) =>
      bidiIsolate('${c.toStringAsFixed(1)} °C');

  /// A one-line summary of [e] for the timeline.
  static String summary(HealthEntry e) => switch (e.kind) {
        HealthEntryKind.temperature => <String>[
            temperature(e.tempC!),
            if (e.method != null) method(e.method!),
          ].join(' · '),
        HealthEntryKind.symptoms =>
          e.symptoms.map(symptom).join("Health_list_separator".tr),
        HealthEntryKind.medicine => <String>[
            bidiIsolate(e.medicine ?? ''),
            if (e.amount != null) bidiIsolate(e.amount!),
          ].join(' · '),
        HealthEntryKind.note => bidiIsolate(e.note ?? ''),
      };
}

/// WHO's message for a [CareLevel], as an inline banner; nothing for
/// [CareLevel.none].
class CareMessage extends StatelessWidget {
  const CareMessage({super.key, required this.level, this.onLearnMore});

  final CareLevel level;

  /// Opens "When to get medical help".
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    return switch (level) {
      CareLevel.none => const SizedBox.shrink(),
      CareLevel.urgent => AppBanner(
          key: const Key('health_care_urgent'),
          tone: AppBannerTone.error,
          icon: Icons.emergency_rounded,
          message: "Health_care_urgent".tr,
          actionLabel: onLearnMore == null ? null : "Health_guide_open".tr,
          onAction: onLearnMore,
        ),
      CareLevel.seeHealthWorker => AppBanner(
          key: const Key('health_care_see'),
          tone: AppBannerTone.warning,
          message: "Health_care_see".tr,
          actionLabel: onLearnMore == null ? null : "Health_guide_open".tr,
          onAction: onLearnMore,
        ),
    };
  }
}
