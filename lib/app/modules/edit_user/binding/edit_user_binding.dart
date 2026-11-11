import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/edit_user/controller/edit_user_controller.dart';

class EditUserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditUserController>(() => EditUserController());
  }
}
