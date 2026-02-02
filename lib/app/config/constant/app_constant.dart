import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/argument_service.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

import '../../core/service/get_storage_service.dart';

class AppConstant {
  static const String appId = "188b14f6-389b-404b-991a-babe68d66589";
  static final AlertService alertService = AlertService();
  static final argumentService = ArgumentService();
  static final getStorage = Get.find<GetStorageService>();
  static final fireStoreHelper = Get.find<FireStoreHelperService>();
}
