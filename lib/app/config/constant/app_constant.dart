import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/argument_service.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

import '../../core/service/get_storage_service.dart';

class AppConstant {
  static const String isLoginKey = "isLogin";
  static const String uidKey = "uid";
  static final AlertService alertService = AlertService();
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 30);
  static const EdgeInsets columnPadding = EdgeInsets.symmetric(horizontal: 15, vertical: 10);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 5, vertical: 10);
  static final argumentService = ArgumentService();
  static final getStorage = Get.find<GetStorageService>();
  static final fireStoreHelper = Get.find<FireStoreHelperService>();
}
