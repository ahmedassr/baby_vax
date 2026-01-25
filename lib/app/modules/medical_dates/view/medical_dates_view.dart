import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';
import 'package:baby_vax/app/core/values/app_image.dart';
import 'package:baby_vax/app/modules/medical_dates/widgets/medical_date_card.dart';
import 'package:baby_vax/app/modules/medical_dates/widgets/medical_dates_empty_state.dart';

import '../widgets/medical_dates_header.dart';

class MedicalDatesView extends GetView<MedicalDatesController> {
  const MedicalDatesView({super.key});

  @override
  Widget build(BuildContext context) {

    return controller.obx(
      (dates) {
        final hasDates = dates != null && dates.isNotEmpty;

        if (!hasDates) {
          return const AppEmptyState(
            animationPath: AppAnimations.noRecords,
          );
        }

        return Stack(
          children: [
            RefreshableListBuilder(
              itemCount: dates.length + 1,
              onRefresh: () => controller.fetchMedicalDates(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return MedicalDatesHeader(
                    hasUpcoming: dates.any(
                      (d) => d.state == MedicalDateStateEnum.pending.label,
                    ),
                  );
                }

                final medicalDate = dates[index - 1];
                return MedicalDateCard(
                  data: medicalDate,
                  onTap: () => controller.onMedicalDatePressed(medicalDate),
                );
              },
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton.extended(
                onPressed: () {
                  // TODO: Wire up add-medical-date flow when available
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(
                  Icons.add,
                  color: AppColors.white,
                ),
                label: const AppText(
                  text: 'Add a custom date',
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        );
      },
      onLoading: const Center(
        child: AppShimmerLoading(),
      ),
      onError: (error) => AppEmptyState(
        message: error,
        animationPath: AppAnimations.noRecords,
      ),
      onEmpty: const AppEmptyState(
        animationPath: AppAnimations.noRecords,
      ),
    );
  }
}
