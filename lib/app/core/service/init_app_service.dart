import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/service/get_storage_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

import '../../config/session/session_manager.dart';

Future<void> initAppService() async {
  await Firebase.initializeApp();
  await GetStorage.init();
  Get.lazyPut<GetStorageService>(() => GetStorageService());
  Get.lazyPut<FireStoreHelperService>(() => FireStoreHelperService());
  SessionManager.uId = AppConstant.getStorage.read(AppConstant.uidKey) ?? "";
}
