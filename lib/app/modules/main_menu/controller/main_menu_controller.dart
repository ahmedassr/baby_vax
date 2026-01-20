import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/main/controller/main_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';

import '../../main/view/main_view.dart';

class MainMenuController extends GetxController {
  final currentIndex = 0.obs;
  final List<BottomNavBarModel> item = [
    BottomNavBarModel(
        title: "Main",
        view: const MainView(),
        icon: Icons.home_filled),
    BottomNavBarModel(
        title: "Medical Dates",
        view: const MedicalDatesView(),
        icon: Icons.calendar_month_rounded,
        showSearch: true),
    BottomNavBarModel(
        title: "Tips",
        view: const TipsView(),
        icon: Icons.privacy_tip,
        showSearch: true),
    BottomNavBarModel(
        title: "Settings", view: const SettingsView(), icon: Icons.settings),
  ];

  void changeValue(index) {
    currentIndex(index);
    switch (index) {
      case 0:
        Get.find<MainController>().fetchUserData();
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
        InternalScreenArgs(user: Get.find<MainController>().userDetails.value));
    Get.toNamed(AppRoutes.editUser);
  }

  @override
  void onClose() {
    currentIndex.value = 0;
    super.onClose();

  }
}
