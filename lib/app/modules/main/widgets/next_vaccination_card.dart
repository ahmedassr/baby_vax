import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_dates/widgets/medical_date_card.dart';
import '../../../core/widget/app_leading_icon.dart';

class NextVaccinationCard extends StatelessWidget {
  final MedicalDatesModel? nextVaccination;
  final VoidCallback? onPressed;

  const NextVaccinationCard({super.key, this.nextVaccination, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
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
          Row(
            children: [
              const AppLeadingIcon(icon: Icons.vaccines),
              12.sbw,
              AppText(
                text: "Next Vaccination",
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          24.sbh,
          if (nextVaccination != null) ...[
            MedicalDateCard(
              data: MedicalDatesModel(
                  name: nextVaccination?.name ?? "",
                  description: nextVaccination?.description ?? "",
                  date: nextVaccination?.date ?? "",
                  state: nextVaccination!.state),
              onTap: onPressed,
            )
          ],
        ],
      ),
    );
  }
}
