import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_image.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';

class MedicalDatesView extends GetView<MedicalDatesController> {
  const MedicalDatesView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<MedicalDatesController>(() => MedicalDatesController());
    return controller.obx(
      (dates) => RefreshableListBuilder(
        itemBuilder: (context, index) {
          return AppDismissibleListItem(
            title: KeyValueRichText(label: "Name:", value: dates![index].name),
            subTitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRichText(label: "Date:", value: dates[index].date),
                KeyValueRichText(label: "State", value: dates[index].state ?? ""),
              ],
            ),
            leadingIcon: Icons.calendar_month_rounded,
            hideTrailingIcon: true,
            disableDismiss: true,
            onTap: () => controller.onMedicalDateTap(dates[index]),
          );
        },
        itemCount: dates?.length ?? 0,
      ),
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
