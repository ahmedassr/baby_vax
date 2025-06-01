import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/get_storage_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

class AppConstant {
  static final AlertService alertService = AlertService();
  static String uid = "";
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 30);
  static const EdgeInsets columnPadding =
      EdgeInsets.symmetric(horizontal: 15, vertical: 10);
}
