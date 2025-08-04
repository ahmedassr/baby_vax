import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/main/controller/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(() => MainController());
  }
}
