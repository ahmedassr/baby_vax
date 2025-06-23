import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';
import 'package:baby_vax/app/core/widget/custom_app_bar.dart';

class SearchOnMedicalDates extends GetView<MedicalDatesController> {
  const SearchOnMedicalDates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Search Medical Dates"),
      body: Padding(
        padding: AppConstant.columnPadding,
        child: Column(
          children: [
            LabeledTextField(
              label: "Which medical dates are you looking for?",
              controller: controller.searchController,
              onChanged: (value) => controller.dates.filterBy(
                  value.toLowerCase(),
                  predicate: (dates, query) =>
                      dates.name.toLowerCase().contains(query.toLowerCase()),
              onSuccess: (filtered) =>controller.setSuccess(filtered),
                onEmpty: () => controller.setEmpty()
              ),
            ),
            const Flexible(child: MedicalDatesView()),
          ],
        ),
      ),
    );
  }
}
