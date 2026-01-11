import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/service/get_storage_service.dart';
import '../../../main.dart';
import '../notification/notification_initializer.dart';

Future<void> initAppService() async {
  await Firebase.initializeApp();
  await NotificationInitializer.init();
  await GetStorage.init();
  // Services
  Get.lazyPut<GetStorageService>(() => GetStorageService());
  Get.lazyPut<FireStoreHelperService>(() => FireStoreHelperService());
  // Session
  SessionManager.uId = AppConstant.getStorage.read(AppConstant.uidKey) ?? "";
  logger.i('✅ App services initialized successfully');
}
