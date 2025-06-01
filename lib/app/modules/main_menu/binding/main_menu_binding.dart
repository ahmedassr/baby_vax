import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainMenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainMenuController>(() => MainMenuController());
  }
}
