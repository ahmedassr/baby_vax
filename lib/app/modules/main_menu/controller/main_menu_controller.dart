import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:baby_vax/app/modules/tips/view/tips_view.dart';

import '../../main/view/main_view.dart';

class MainMenuController extends GetxController {
  final currentIndex = 0.obs;
  final List<BottomNavBarModel> item = [
    BottomNavBarModel(title: "Main", view: const MainView(), icon: Icons.home_filled),
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

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  void changeValue(index) {
    currentIndex(index);
  }

  void onSearchPressed() {}

  void onAddPressed() {}
}
