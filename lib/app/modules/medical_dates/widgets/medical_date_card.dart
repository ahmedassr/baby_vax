import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/medical_date_status_badge.dart';
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
    final isDark = context.isDarkMode;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.10),
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
                                text: AppDateFormat.date(data.date),
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
                            MedicalDateStatusBadge(state: data.state),
                          ],
                        ),
                        8.sbh,
                        AppText(
                          text: bidiIsolate(data.displayName),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textBlack,
                          ),
                        ),
                        if (data.displayDescription.isNotEmpty) ...[
                          4.sbh,
                          AppText(
                            text: bidiIsolate(data.displayDescription),
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
}
