import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/tip_details/controller/tip_details_controller.dart';

class TipDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TipDetailsController>(() => TipDetailsController());
  }
}
