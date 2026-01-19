import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';
import 'package:baby_vax/app/modules/medical_dates/widgets/medical_date_card.dart';
import '../../../core/shared_model/remaining_time_result.dart';
import '../../../core/utils/app_extension.dart';
import '../../../core/widget/app_leading_icon.dart';

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
              Row(
                children: [
                  const AppLeadingIcon(icon: Icons.vaccines),
                  12.sbw,
                  Expanded(
                    child: AppText(
                      text: "Next Vaccination",
                      maxLines: 2,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
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
        ),
        Positioned(right: 16, top: 8, child: _buildCountBadge(context))
      ],
    );
  }

  Widget _buildCountBadge(BuildContext context) {
    final vaxDate = DateTime.tryParse(nextVaccination?.date ?? "");
    if (vaxDate == null) return const SizedBox.shrink();

    final RemainingTimeResult result = vaxDate.remainingTime;
    final badgeColor = result.status.badgeBackgroundColor(context);


    return Container(
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20), bottomLeft: Radius.circular(8)),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.33),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(left: 8),
      child: AppText(
        text: result.value != null
            ? "${result.value} ${result.status.name}"
            : result.status.name ?? "",
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: badgeColor.withValues(alpha: context.isDarkMode ? 0.95 : 1.0),
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
