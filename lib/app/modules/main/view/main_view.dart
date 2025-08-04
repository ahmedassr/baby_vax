import 'package:baby_vax/app/core/imports/import_manger.dart';

import '../controller/main_controller.dart';
import '../widgets/user_card.dart';
import '../widgets/user_measurements_card.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<MainController>(() => MainController());
    return SingleChildScrollView(
      child: controller.obx(
        (state) => RefreshableListBuilder(
          itemCount: 1,
          onRefresh: () => controller.fetchUserData(),
          itemBuilder: (_, index) {
            return Column(
              children: [
                UserCard(
                    name: controller.userDetails.value?.name ?? "y/n",
                    email: controller.userDetails.value?.email ?? "y/n"),
                50.sbh,
                UserMeasurementCard(
                    weight: controller.userDetails.value?.weight ?? "_",
                    height: controller.userDetails.value?.height ?? "_",
                    bloodPercentage:
                        controller.userDetails.value?.bloodPercentage ?? "_",
                    headSize: controller.userDetails.value?.headSize ?? "_"),
              ],
            );
          },
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
      ),
    );
  }
}
