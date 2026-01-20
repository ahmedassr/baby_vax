import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';

import '../shared_model/remaining_time_result.dart';

class VaccinationCountBadge extends StatelessWidget {
  final MedicalDatesModel? nextVaccination;

  const VaccinationCountBadge({super.key,  this.nextVaccination});

  @override
  Widget build(BuildContext context) {
    if (nextVaccination?.date == null) return const SizedBox.shrink();

    final RemainingTimeResult result = nextVaccination!.date.remainingTime;
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
