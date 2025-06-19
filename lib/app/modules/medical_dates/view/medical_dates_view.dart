import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/app_image.dart';

class MedicalDatesView extends GetView<MedicalDatesController> {
  const MedicalDatesView({super.key});
// @override
//   Widget build(BuildContext context) {
//     return Center();
//   }
  @override
  Widget build(BuildContext context) {
    return controller.obx(
      (dates) => RefreshableListBuilder(
        itemBuilder: (context, index) {
          return AppDismissibleListItem(
            title: KeyValueRichText(
                label: "Name:", value: dates![index].name),
            subTitle: KeyValueRichText(
                label: "Date:", value: dates[index].date),
            leadingIcon: Icons.assistant_photo_rounded,
            hideTrailingIcon: true,
            disableDismiss: true,
            onTap: () {},
          );
        },
        itemCount: dates?.length ?? 0,
      ),
    );
  }
}
