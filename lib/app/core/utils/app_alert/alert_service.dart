import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_alert/alert_widget.dart';
import 'package:baby_vax/app/core/utils/app_alert/app_alert_model.dart';

class AlertService extends GetxService {
  Future<bool?> showAlert(AlertModel alert) {
    if (Get.isDialogOpen ?? false) {
      Get.back(result: true);
    }
    return Get.dialog(AlertWidget(alert: alert), barrierDismissible: true);
  }

  void showError({String message, VoidCallback? yesAction}) {
    showAlert(AlertModel.error(message: message, yesAction: yesAction));
  }
}
