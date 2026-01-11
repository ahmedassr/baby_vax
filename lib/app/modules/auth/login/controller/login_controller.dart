import 'package:baby_vax/app/core/notification/application/notification_coordinator.dart';
import '../../../../core/imports/import_manger.dart';

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
    super.onClose();
    for (var controller in loginController.values) {
      controller.dispose();
    }
  }

  Future userLogin() async {
    String email = loginController["email"]?.text.trim() ?? "";
    String password = loginController["password"]?.text.trim() ?? "";
    if (email.isEmpty) {
      emailErrorText("Email can't be empty.");
      return;
    }
    if (password.isEmpty) {
      passwordErrorText("password can't be empty.");
      return;
    }
    setLoading();
    try {
      final authResult = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (authResult.user != null) {
        AppConstant.getStorage.write(AppConstant.isLoginKey, true);
        AppConstant.getStorage.write(AppConstant.uidKey, authResult.user?.uid);
        SessionManager.uId = authResult.user?.uid ?? "";
        await AppConstant.fireStoreHelper.updateFcmToken();
        await Get.find<NotificationCoordinator>().rescheduleAllVaccines(
            userId: SessionManager.uId,
            userName: authResult.user?.displayName ?? "Your baby");
        Get.toNamed(AppRoutes.mainMenu);
        setSuccess();
      } else {
        setError("Failed to login.");
      }
    } on FirebaseAuthException catch (error) {
      setError(getFriendlyErrorMessage(error.toString()));
      return;
    }
  }
}
