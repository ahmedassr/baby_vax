import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}
