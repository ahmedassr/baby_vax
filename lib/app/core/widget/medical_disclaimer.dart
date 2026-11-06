import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Standing notice that the schedule is informational.
///
/// Baby Vax shows a generated immunization schedule, which makes it a health
/// app: parents must not read it as medical advice, and national schedules
/// differ between countries and change over time. Play's health-app policy
/// also expects the disclaimer and the schedule's source to be stated in the
/// app, not only in the store listing.
///
/// Shown on sign-up (where the schedule is created) and above the schedule
/// itself.
class MedicalDisclaimer extends StatelessWidget {
  const MedicalDisclaimer({super.key, this.compact = false});

  /// Compact drops the heading, for use inside a scrolling list header.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Semantics(
      // Read as one block, so a screen reader does not split the notice from
      // its heading.
      container: true,
      label: compact
          ? "MedicalDisclaimer_body".tr
          : '${"MedicalDisclaimer_title".tr}. '
              '${"MedicalDisclaimer_body".tr} '
              '${"MedicalDisclaimer_source".tr}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              8.sbw,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!compact) ...<Widget>[
                      Text(
                        "MedicalDisclaimer_title".tr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      4.sbh,
                    ],
                    Text(
                      "MedicalDisclaimer_body".tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (!compact) ...<Widget>[
                      4.sbh,
                      Text(
                        "MedicalDisclaimer_source".tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
