import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/widgets/next_vaccination_card.dart';
import 'package:baby_vax/app/modules/home/widgets/notifications_off_banner.dart';
import '../controller/home_controller.dart';
import '../widgets/profile_card.dart';
import '../widgets/user_measurements_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<HomeController>(() => HomeController());
    return controller.obx(
      (state) => RefreshableListBuilder(
        itemCount: 1,
        onRefresh: () => controller.fetchUserData(),
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Obx(() => controller.notificationsOff.value
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NotificationsOffBanner(
                          onOpenSettings: controller.openNotificationSettings,
                        ),
                      )
                    : const SizedBox.shrink()),
                ProfileCard(
                  name: controller.userDetails.value?.name ?? "-",
                  email: controller.userDetails.value?.email ?? "-",
                  onEditPressed: () {
                    try {
                      Get.find<MainMenuController>().onEditPressed();
                    } catch (e) {
                      AppConstant.argumentService.setArgument(
                        InternalScreenArgs(
                          user: controller.userDetails.value,
                        ),
                      );
                      Get.toNamed(AppRoutes.editUser);
                    }
                  },
                ),
                5.sbh,
                UserMeasurementCard(
                  weight: controller.userDetails.value?.weight ?? "_",
                  height: controller.userDetails.value?.height ?? "_",
                  bloodPercentage:
                      controller.userDetails.value?.bloodPercentage ?? "_",
                  headSize: controller.userDetails.value?.headSize ?? "_",
                ),
                5.sbh,
                NextVaccinationCard(
                  nextVaccination: controller.nextVaccination.value,
                  onPressed: controller.onNextVaccinationPressed,
                )
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
      onEmpty: Center(
        child: AppEmptyState(
          message: "TipsView_empty_state_text".tr,
          animationPath: AppAnimations.noRecords,
        ),
      ),
    );
  }
}
