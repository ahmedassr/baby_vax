import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainMenuController extends GetxController {
  final currentIndex = 0.obs;
  final List<BottomNavBarModel> item = [
    BottomNavBarModel(title: "Main", view: const MainView(), icon: Icons.home_filled),
    BottomNavBarModel(
        title: "Medical Dates",
        view: Center(),
        icon: Icons.calendar_month_rounded),
    BottomNavBarModel(
        title: "Tips and Advice", view: Center(), icon: Icons.privacy_tip),
    BottomNavBarModel(title: "Settings", view: Center(), icon: Icons.settings),
  ];

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  void changeValue(index) {
    currentIndex(index);
  }
}
