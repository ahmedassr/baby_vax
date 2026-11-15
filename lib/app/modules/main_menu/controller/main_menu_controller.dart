import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';

import '../../home/view/home_view.dart';

/// The four tabs: Home, Schedule, Growth, Settings. Growth replaced Tips
/// (phone review): tips are now Home's "Tip of the day" with "See all
/// tips". v1.0 also had search/add/edit app-bar actions whose handlers were
/// empty; they are gone.
class MainMenuController extends GetxController {
  final currentIndex = 0.obs;

  final List<BottomNavBarModel> item = const <BottomNavBarModel>[
    BottomNavBarModel(
        title: "MainMenuController_home_title",
        view: HomeView(),
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded),
    BottomNavBarModel(
        title: "MainMenuController_medical_dates_title",
        view: MedicalDatesView(),
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note_rounded),
    BottomNavBarModel(
        title: "Growth_title",
        view: GrowthView(inTab: true),
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded),
    BottomNavBarModel(
        title: "MainMenuController_settings_title",
        view: SettingsView(),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded),
  ];

  /// The Growth tab's index.
  static const int growthTab = 2;

  void changeValue(int index) {
    if (index != currentIndex.value) AppHaptics.selection();
    currentIndex(index);
    switch (index) {
      case 0:
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchUserData();
        }
      case 1:
        if (Get.isRegistered<MedicalDatesController>()) {
          Get.find<MedicalDatesController>().fetchMedicalDates();
        }
      case 2:
        if (Get.isRegistered<GrowthController>()) {
          Get.find<GrowthController>().fetch();
        }
    }
  }

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
