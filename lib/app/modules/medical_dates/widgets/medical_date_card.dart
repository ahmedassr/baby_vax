import 'package:baby_vax/app/core/imports/import_manger.dart';
import '../../../core/widget/app_leading_icon.dart';
import '../../../core/widget/vaccination_count_badge.dart';

class MedicalDateCard extends StatelessWidget {
  final MedicalDatesModel data;
  final VoidCallback? onTap;
  final bool showCount;

  const MedicalDateCard(
      {super.key, required this.data, this.onTap, this.showCount = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.isDarkMode;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceVariant.withValues(alpha: 0.6)
                : colorScheme.surface,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLeadingIcon(
                      icon: Icons.calendar_month_rounded,
                    ),
                    16.sbw,
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AppText(
                                text: data.date.toString(),
                                maxLines: 2,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textWhite
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            8.sbw,
                            _buildStatusChip(context),
                          ],
                        ),
                        8.sbh,
                        AppText(
                          text: data.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textBlack,
                          ),
                        ),
                        if (data.description.isNotEmpty) ...[
                          4.sbh,
                          AppText(
                            text: data.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.greyMedium
                                  : AppColors.greyDark,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showCount) ...[
          Positioned(
              right: 0,
              top: 2,
              child: VaccinationCountBadge(
                nextVaccination: data,
              ))
        ]
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final stateEnum = MedicalDateStateEnum.fromLabel(data.state);
    Color bg;
    Color fg;

    switch (stateEnum) {
      case MedicalDateStateEnum.completed:
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case MedicalDateStateEnum.skipped:
        bg = theme.colorScheme.error.withValues(alpha: 0.12);
        fg = theme.colorScheme.error;
        break;
      case MedicalDateStateEnum.pending:
        bg = AppColors.primary.withValues(alpha: 0.1);
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        text: data.state,
        style: AppTextStyles.captionMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
