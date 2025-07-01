import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/argument_service.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_service.dart';

class AppConstant {
  static String uId = "";
  static final AlertService alertService = AlertService();
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 30);
  static const EdgeInsets columnPadding = EdgeInsets.symmetric(horizontal: 15, vertical: 10);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 5, vertical: 10);
  static final argumentService = ArgumentService();
}
