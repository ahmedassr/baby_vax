import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_date_details/widgets/medical_date_actions.dart';
import 'package:baby_vax/app/modules/medical_date_details/widgets/medical_date_detail_card.dart';

class MedicalDateDetailsView extends GetView<MedicalDateDetailsController> {
  const MedicalDateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: controller.medicalDate?.name ?? "Medical Date Details",
        fontSize: 18,
      ),
      body: controller.obx(
        (_) => SingleChildScrollView(
          child: Padding(
            padding: AppConstant.columnPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.sbh,
                AppText(
                  text: "Vaccination details and notes",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                24.sbh,
                MedicalDateDetailCard(
                  name: controller.medicalDate?.name,
                  date: controller.medicalDate?.date,
                  description: controller.medicalDate?.description,
                  state: controller.medicalDate?.state,
                ),
                32.sbh,
                MedicalDateActions(
                  isCompleted: controller.medicalDate?.state ==
                      MedicalDateStateEnum.completed,
                  isActive: controller.isActive,
                  onMarkCompleted: controller.updateState,
                ),
                24.sbh,
              ],
            ),
          ),
        ),
        onLoading: const Center(
          child: CupertinoActivityIndicator(),
        ),
        onError: (error) {
          if (error != null && error.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppConstant.alertService.showError(message: error);
              controller.setSuccess();
            });
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
