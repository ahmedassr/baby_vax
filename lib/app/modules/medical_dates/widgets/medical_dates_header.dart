import '../../../core/imports/import_manger.dart';

class MedicalDatesHeader extends StatelessWidget {
  final bool hasUpcoming;

  const MedicalDatesHeader({super.key, required this.hasUpcoming});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "MedicalDatesHeader_medical_dates_label".tr,
            style: AppTextStyles.headLineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          8.sbh,
          AppText(
            text: hasUpcoming
                ? "MedicalDatesHeader_upcoming_appointments_label".tr
                : "MedicalDatesHeader_no_upcoming_appointments_label".tr,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          12.sbh,
          // Standing reminder that this schedule is informational; required
          // for a health app and expected by Play's health policy.
          const MedicalDisclaimer(),
          16.sbh,
        ],
      ),
    );
  }
}
