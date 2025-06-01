import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SingleChildScrollView(
      child: Padding(
        padding: AppConstant.columnPadding,
        child: Column(
          children: [
            UserCard(
                name: controller.user.value?.name ?? "",
                email: controller.user.value?.email ?? ""),
            50.sbh,
            UserMeasurementCard(
                weight: controller.user.value?.weight ?? "",
                height: controller.user.value?.height ?? "",
                bloodPercentage: controller.user.value?.bloodPercentage ?? "",
                headSize: controller.user.value?.headSize ?? ""),
          ],
        ),
      ),
    );
  }
}
