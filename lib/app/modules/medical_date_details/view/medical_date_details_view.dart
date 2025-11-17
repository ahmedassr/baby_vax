import 'package:baby_vax/app/core/imports/import_manger.dart';

class MedicalDateDetailsView extends GetView<MedicalDateDetailsController> {
  const MedicalDateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: controller.medicalDate?.name ?? "",
        fontSize: 15,
      ),
      body: controller.obx(
          (_) => SingleChildScrollView(
                child: Padding(
                  padding: AppConstant.columnPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      20.sbh,
                      KeyValueRichText(
                          label: "Name: ",
                          value: controller.medicalDate?.name ?? ""),
                      20.sbh,
                      KeyValueRichText(
                          label: "Due Date: ",
                          value: controller.medicalDate?.date ?? "00-00-0000"),
                      20.sbh,
                      KeyValueRichText(
                          label: "State: ",
                          value: controller.medicalDate?.state.label ?? ""),
                      70.sbh,
                      if (controller.medicalDate?.state !=
                          MedicalDateStateEnum.completed)
                        AppButton(
                          onPressed: controller.isActive
                              ? controller.updateState
                              : null,
                          text: MedicalDateStateEnum.completed.label,
                        ),
                      if (controller.medicalDate?.state ==
                          MedicalDateStateEnum.completed)
                        AppButton(
                          text: "Done",
                          onPressed: () => Get.back(),
                        ),
                    ],
                  ),
                ),
              ),
          onLoading: const Center(
            child: CupertinoActivityIndicator(),
          ), onError: (error) {
        if (error != null && error.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppConstant.alertService.showError(message: error);
            controller.setSuccess();
          });
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
