import 'package:baby_vax/app/core/notification/data/onesignal_notification_provider.dart';
import '../../../../core/imports/import_manger.dart';
import '../../../home/controller/home_controller.dart';

class LoginController extends GetxController with StateMixin, StateMixinHelper {
  final loginController = {
    "email": TextEditingController(),
    "password": TextEditingController()
  };
  final FirebaseAuth auth = FirebaseAuth.instance;
  final emailErrorText = "".obs;
  final passwordErrorText = "".obs;

  @override
  void onInit() {
    super.onInit();
    setSuccess();
  }

  @override
  void onClose() {
    for (var controller in loginController.values) {
      controller.dispose();
    }
    super.onClose();
  }

  Future userLogin() async {
    String email = loginController["email"]?.text.trim() ?? "";
    String password = loginController["password"]?.text.trim() ?? "";
    if (email.isEmpty) {
      emailErrorText("empty_email_error_msg".tr);
      return;
    }
    if (password.isEmpty) {
      passwordErrorText("empty_password_error_msg".tr);
      return;
    }
    setLoading();
    try {
      final authResult = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (authResult.user != null) {
       await AppConstant.getStorage.write(StorageKey.isLoginKey, true);
       await AppConstant.getStorage.write(StorageKey.uidKey, authResult.user?.uid);
        SessionManager.uId = authResult.user?.uid ?? "";
        await AppConstant.fireStoreHelper.updateFcmToken();
        await Get.find<NotificationCoordinator>().rescheduleAllVaccines(
            userId: SessionManager.uId,
            userName: authResult.user?.displayName ?? "Your baby");
        await Get.find<OneSingleNotificationProvider>()
            .setUser(SessionManager.uId);
        await Get.find<HomeController>().fetchUserData();
        setSuccess();
        Get.toNamed(AppRoutes.mainMenu);
      } else {
        setError("LoginController_login_failed_msg".tr);
      }
    } on FirebaseAuthException catch (error) {
      setError(getFriendlyErrorMessage(error.toString()));
      return;
    }
  }
}
