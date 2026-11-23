import 'package:baby_vax/app/core/imports/import_library.dart';

import '../controller/reminders_controller.dart';

class RemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemindersController>(() => RemindersController());
  }
}
