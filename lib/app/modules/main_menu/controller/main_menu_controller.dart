import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/view/health_view.dart';

import '../../home/view/home_view.dart';

/// The four tabs: Home, Schedule, Health, Settings. Health replaced Tips
/// (phone review): tips are Home's "Tip of the day" and a row in Settings.
/// v1.0 also had search/add/edit app-bar actions whose handlers were
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
        title: "Health_title",
        view: HealthView(),
        icon: Icons.monitor_heart_outlined,
        selectedIcon: Icons.monitor_heart_rounded),
    BottomNavBarModel(
        title: "MainMenuController_settings_title",
        view: SettingsView(),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded),
  ];

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
        if (Get.isRegistered<HealthController>()) {
          Get.find<HealthController>().fetch();
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
