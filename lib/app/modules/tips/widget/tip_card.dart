import 'package:baby_vax/app/core/imports/import_manger.dart';

class TipCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const TipCard({
    required this.title,
    required this.description,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = context.isDarkMode;

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
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
          elevation: 2,
          shadowColor: AppColors.black.withValues(alpha: 0.08),
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconBadge(icon: Icons.privacy_tip_outlined),
                  16.sbw,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        6.sbh,
                        AppText(
                          text: description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
