import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/main_menu/controller/main_menu_controller.dart';

import '../controller/main_controller.dart';
import '../widgets/profile_card.dart';
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ProfileCard(
                    name: controller.userDetails.value?.name ?? "y/n",
                    email: controller.userDetails.value?.email ?? "y/n",
                    onEditPressed: () {
                      try {
                        Get.find<MainMenuController>().onEditPressed();
                      } catch (e) {
                        // Fallback if MainMenuController is not available
                        AppConstant.argumentService.setArgument(
                          InternalScreenArgs(
                            user: controller.userDetails.value,
                          ),
                        );
                        Get.toNamed(AppRoutes.editUser);
                      }
                    },
                  ),
                  24.sbh,
                  UserMeasurementCard(
                    weight: controller.userDetails.value?.weight ?? "_",
                    height: controller.userDetails.value?.height ?? "_",
                    bloodPercentage:
                        controller.userDetails.value?.bloodPercentage ?? "_",
                    headSize: controller.userDetails.value?.headSize ?? "_",
                  ),
                  24.sbh,
                ],
              ),
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
