import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/utils/app_alert/app_alert_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    setSuccess();
    super.onInit();
  }

  @override
  void onClose() {
    loginController.forEach((key, controller) => controller.dispose());
    super.onClose();
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
      final result = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (result.user != null) {
        setSuccess();
        AppConstant.alertService.showAlert(AlertModel.success(
            message: "User login successfully", yesAction: () => Get.back()));
      } else {
        AppConstant.alertService.showError(
            message: "Failed to login.", yesAction: () => Get.back());
      }
    } on FirebaseAuthException catch (error) {
      AppConstant.alertService.showError(
          message: error.toString() ?? "Failed to login.",
          yesAction: () => Get.back());
      print(error.toString());
      return;
    }
  }
}
