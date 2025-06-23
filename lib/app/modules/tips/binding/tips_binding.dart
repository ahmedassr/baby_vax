import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';

class TipsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TipsController>(() => TipsController());
  }
}
