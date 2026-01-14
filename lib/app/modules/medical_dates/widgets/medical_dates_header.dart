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
            text: "Medical Dates",
            style: AppTextStyles.headLineSmall.copyWith(
              color: colorScheme.onBackground,
            ),
          ),
          8.sbh,
          AppText(
            text: hasUpcoming
                ? "Track your baby's upcoming and past appointments."
                : "No upcoming appointments. Add medical dates to stay on track.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          16.sbh,
        ],
      ),
    );
  }
}
