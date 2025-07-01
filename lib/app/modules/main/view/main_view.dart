import 'package:baby_vax/app/core/imports/import_manger.dart';

import '../controller/main_controller.dart';
import '../widgets/user_card.dart';
import '../widgets/user_measurements_card.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<MainController>(() => MainController());
    // TODO: implement build
    return SingleChildScrollView(
      child: Padding(
        padding: AppConstant.columnPadding,
        child: Column(
          children: [
            UserCard(
                name: controller.user.value?.name ?? "Ahmed Al-Assar",
                email: controller.user.value?.email ?? "ahmedassr360@gmail.com"),
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
