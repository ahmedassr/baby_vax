import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';

class SearchOnMedicalDates extends GetView<MedicalDatesController> {
  const SearchOnMedicalDates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "SearchOnMedicalDates_title".tr),
      body: Padding(
        padding: AppSpacing.columnPadding,
        child: controller.obx(
          (state) => Column(
            children: [
              LabeledTextField(
                label: "SearchOnMedicalDates_search_field_label".tr,
                controller: controller.searchController,
                onChanged: (value) => state?.filterBy(value.toLowerCase(),
                    predicate: (dates, query) =>
                        dates.name.toLowerCase().contains(query.toLowerCase()),
                    onSuccess: (filtered) => controller.setSuccess(filtered),
                    onEmpty: () => controller.setEmpty()),
              ),
              const Flexible(child: MedicalDatesView()),
            ],
          ),
          onLoading: const Center(
            child: AppShimmerLoading(),
          ),
          onEmpty: const AppEmptyState(
            animationPath: AppAnimations.noRecords,
          ),
          onError: (error) => AppEmptyState(
            message: error,
            animationPath: AppAnimations.noRecords,
          ),
        ),
      ),
    );
  }
}
