import 'package:baby_vax/app/core/service/get_storage_service.dart';

import '../../../../core/imports/import_manger.dart';

class LoginController extends GetxController with StateMixin, StateMixinHelper {
  final loginController = {
    "email": TextEditingController(),
    "password": TextEditingController()
  };
  final FirebaseAuth auth = FirebaseAuth.instance;
  final emailErrorText = "".obs;
  final passwordErrorText = "".obs;
  final getStorage = Get.find<GetStorageService>();

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
        getStorage.write("isLogin", true);
        getStorage.write("uid", result.user?.uid);
        AppConstant.alertService.showAlert(AlertModel.success(
          message: "User login successfully",
          yesAction: () => Get.toNamed(AppRoutes.mainMenu),
        ));
      } else {
        setError("Failed to login.");
      }
    } on FirebaseAuthException catch (error) {
      setError(getFriendlyErrorMessage(error.toString()));
      return;
    }
  }
}
