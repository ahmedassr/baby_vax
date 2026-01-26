import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';

import '../../home/view/home_view.dart';

class MainMenuController extends GetxController {
  final currentIndex = 0.obs;
  final List<BottomNavBarModel> item = [
    BottomNavBarModel(
        title: "MainMenuController_home_title".tr,
        view: const HomeView(),
        icon: Icons.home_filled),
    BottomNavBarModel(
        title: "MainMenuController_medical_dates_title".tr,
        view: const MedicalDatesView(),
        icon: Icons.calendar_month_rounded,
        showSearch: true),
    BottomNavBarModel(
        title: "MainMenuController_tips_title".tr,
        view: const TipsView(),
        icon: Icons.privacy_tip,
        showSearch: true),
    BottomNavBarModel(
        title: "MainMenuController_settings_title".tr, view: const SettingsView(), icon: Icons.settings),
  ];

  void changeValue(index) {
    currentIndex(index);
    switch (index) {
      case 0:
        Get.find<HomeController>().fetchUserData();
        break;
      case 1:
        Get.find<MedicalDatesController>().fetchMedicalDates();
      case 2:
        Get.find<TipsController>().fetchTips();
    }
  }

  void onSearchPressed() {}

  void onAddPressed() {}

  void onEditPressed() {
    AppConstant.argumentService.setArgument(
        InternalScreenArgs(user: Get.find<HomeController>().userDetails.value));
    Get.toNamed(AppRoutes.editUser);
  }

  @override
  void onClose() {
    currentIndex.value = 0;
    super.onClose();

  }
}
