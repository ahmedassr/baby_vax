import 'package:baby_vax/app/core/imports/import_library.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
}
