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
        await AppConstant.getStorage
            .write(StorageKey.uidKey, authResult.user?.uid);
        SessionManager.uId = authResult.user?.uid ?? "";
        final HomeController home = Get.find<HomeController>();
        await home.fetchUserData();
        // The child's name is in the Firestore user doc. Auth displayName is
        // never set by this app. Cached so app-start reminder top-ups work
        // offline.
        final String childName =
            reminderChildName(home.userDetails.value?.name);
        await AppConstant.getStorage
            .write(StorageKey.userNameKey, home.userDetails.value?.name ?? "");

        final NotificationCoordinator reminders =
            Get.find<NotificationCoordinator>();
        // Ask now rather than at cold start: the user has just signed in and a
        // schedule exists, so the prompt has visible context.
        final bool granted = await reminders.requestPermission();
        await reminders.syncFromFirestore(
          userId: SessionManager.uId,
          userName: childName,
        );
        if (!granted) {
          // Reminders stay scheduled; they just will not be shown until the
          // user enables notifications in system settings.
          logger.w('Notification permission denied after login');
        }
        setSuccess();
        Get.toNamed(AppRoutes.mainMenu);
      } else {
        setError("LoginController_login_failed_msg".tr);
      }
    } on FirebaseAuthException catch (error) {
      setError(friendlyFirebaseError(error));
      return;
    }
  }
}
