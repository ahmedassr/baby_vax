import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/main_menu/binding/main_tab_binding.dart';

class AppBinding extends Bindings{
  @override
  void dependencies() {
    MainTabsBinding().dependencies();
  }

}