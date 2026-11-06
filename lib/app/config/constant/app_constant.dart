import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/argument_service.dart';
import 'package:baby_vax/app/core/service/fire_store_helper_service.dart';
import 'package:baby_vax/app/core/service/notification_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

import '../../core/service/get_storage_service.dart';

class AppConstant {
  // Notification Reminder Time
  static const int morningReminderHour = 9;
  static const int eveningReminderHour = 18;
  // Service
  static final AlertService alertService = AlertService();
  static final argumentService = ArgumentService();
  static final notificationService = NotificationService();
  static final getStorage = Get.find<GetStorageService>();
  static final fireStoreHelper1 = Get.find<FireStoreHelperService>();
}
