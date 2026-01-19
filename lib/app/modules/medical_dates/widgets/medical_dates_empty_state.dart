import 'package:baby_vax/app/core/imports/import_manger.dart';

class MedicalDatesEmptyState extends StatelessWidget {
  final String? message;
  final VoidCallback? onAddPressed;

  const MedicalDatesEmptyState({
    super.key,
    this.message,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            24.sbh,
            AppText(
              text: "No medical dates yet",
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            8.sbh,
            AppText(
              text: message ??
                  "Add your baby's vaccination and medical appointments to stay on track.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            24.sbh,
            if (onAddPressed != null)
              AppButton(
                text: "Add medical date",
                onPressed: onAddPressed,
              ),
          ],
        ),
      ),
    );
  }
}





