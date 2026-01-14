import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/auth/sign_up/controller/sign_up_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
