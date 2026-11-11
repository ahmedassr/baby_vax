import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/vaccination_count_badge.dart';
import 'package:baby_vax/app/modules/medical_dates/widgets/medical_date_card.dart';

class NextVaccinationCard extends StatelessWidget {
  final MedicalDatesModel? nextVaccination;
  final VoidCallback? onPressed;

  const NextVaccinationCard({super.key, this.nextVaccination, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.sbh,
              Row(
                children: [
                  const AppIconBadge(icon: Icons.vaccines),
                  12.sbw,
                  Expanded(
                    child: AppText(
                      text: "NextVaccinationCard_next_vaccination_title".tr,
                      maxLines: 2,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (nextVaccination != null) ...[
                MedicalDateCard(
                  data: nextVaccination!,
                  onTap: onPressed,
                  showCount: false,
                )
              ],
            ],
          ),
        ),
        Positioned(
            right: 16,
            top: 8,
            child: VaccinationCountBadge(
              nextVaccination: nextVaccination,
            ))
      ],
    );
  }
}
