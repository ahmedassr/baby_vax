
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/get_storage_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

Future<void> initAppService() async {
  await GetStorage.init();
  Get.lazyPut<GetStorageService>(() => GetStorageService());
  Get.lazyPut<AlertService>(() => AlertService());
}
