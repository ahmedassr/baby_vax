import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';

class SearchOnTips extends GetView<TipsController> {
  const SearchOnTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "SearchOnTips_title".tr),
      body: Padding(
        padding: AppSpacing.columnPadding,
        child: Column(
          children: [
            LabeledTextField(
              label: "SearchOnTips_search_field_label".tr,
              controller: controller.searchController,
              onChanged: (value) => controller.tips.filterBy(value,
                  predicate: (tip, query) =>
                      tip.title.toLowerCase().contains(query),
                  onSuccess: (filtered) => controller.setSuccess(filtered),
                  onEmpty: () => controller.setEmpty()),
            ),
            const Flexible(child: TipsView()),
          ],
        ),
      ),
    );
  }
}
