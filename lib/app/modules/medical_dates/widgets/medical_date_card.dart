import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

class MedicalDateCard extends StatelessWidget {
  final MedicalDatesModel date;
  final VoidCallback? onTap;

  const MedicalDateCard({
    super.key,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceVariant.withValues(alpha: 0.6)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeadingIcon(context),
                16.sbw,
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppText(
                text: date.date,
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
          text: date.name,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
        ),
        if (date.description.isNotEmpty) ...[
          4.sbh,
          AppText(
            text: date.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.greyMedium : AppColors.greyDark,
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;

    switch (date.state) {
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
        text: date.state.label,
        style: AppTextStyles.captionMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}


