import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

class NotificationService extends GetxService {
  Future<void> updateFcmToken({String? token}) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      logger.e("❌ Failed to get FCM Token");
      return;
    }
    await AppConstant.fireStoreHelper1.updateData(
        path: AppPath.currentUserDoc, data: {'fcmToken': token ?? fcmToken});

    logger
        .i("✅ FCM Token updated successfully: ${fcmToken.substring(0, 20)}...");
  }
}
