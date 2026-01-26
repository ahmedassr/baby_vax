import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/medical_date_status_badge.dart';

class MedicalDateDetailCard extends StatelessWidget {
  final String? name;
  final String? date;
  final String? description;
  final String? state;

  const MedicalDateDetailCard({
    super.key,
    this.name,
    this.date,
    this.description,
    this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(context),
                16.sbw,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: name?.isNotEmpty == true ? name! : "MedicalDateDetailCard_medical_date_label".tr,
                        maxLines: 5,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      8.sbh,
                      if (date != null && date!.isNotEmpty)
                        AppText(
                          text: date!,
                          maxLines: 2,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        AppText(
                          text: "MedicalDateDetailCard_date_fallback_label".tr,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                if (state != null) ...[
                  8.sbw,
                  MedicalDateStatusBadge(state: state!),
                ],
              ],
            ),
            if (description != null && description!.isNotEmpty) ...[
              20.sbh,
              AppText(
                text: "MedicalDateDetailCard_notes_label".tr,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              8.sbh,
              AppText(
                text: description!,
                maxLines: 20,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.vaccines_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}





