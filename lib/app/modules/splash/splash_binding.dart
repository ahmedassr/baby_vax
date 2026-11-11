import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}
