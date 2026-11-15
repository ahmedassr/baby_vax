import '../../../../core/imports/import_manger.dart';
import '../../../../core/utils/validators.dart';
import '../../../home/controller/home_controller.dart';

/// Signs a parent in.
///
/// v1.0 put the whole screen into an error state on a failed sign-in, which
/// returned an empty widget and opened a dialog from a post-frame callback:
/// the form vanished behind the dialog. Now field problems are shown under
/// the field and server problems in a banner above the form, and the form
/// never goes away.
class LoginController extends GetxController {
  LoginController({
    Future<String?> Function(String email, String password)? signIn,
    Future<void> Function(String uid)? onSignedIn,
  })  : _signIn = signIn ?? _firebaseSignIn,
        _onSignedIn = onSignedIn ?? _prepareSession;

  final Future<String?> Function(String email, String password) _signIn;
  final Future<void> Function(String uid) _onSignedIn;

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();

  /// A failure from the server: wrong password, offline, too many attempts.
  final RxnString authError = RxnString();

  final RxBool isSubmitting = false.obs;

  static Future<String?> _firebaseSignIn(String email, String password) async {
    final UserCredential result = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return result.user?.uid;
  }

  /// Everything that has to happen after a successful sign-in, before the
  /// schedule is shown: cache the session, load the profile, reschedule the
  /// reminders.
  static Future<void> _prepareSession(String uid) async {
    await AppConstant.getStorage.write(StorageKey.isLoginKey, true);
    await AppConstant.getStorage.write(StorageKey.uidKey, uid);
    SessionManager.uId = uid;
    final HomeController home = Get.find<HomeController>();
    await home.fetchUserData();
    // The child's name is in the Firestore user doc. Auth displayName is
    // never set by this app. Cached so app-start reminder top-ups work
    // offline.
    final String? name = home.userDetails.value?.name;
    await AppConstant.getStorage.write(StorageKey.userNameKey, name ?? "");

    final NotificationCoordinator reminders =
        Get.find<NotificationCoordinator>();
    // Ask now rather than at cold start: the user has just signed in and a
    // schedule exists, so the prompt has visible context.
    final bool granted = await reminders.requestPermission();
    await reminders.syncFromFirestore(
        userId: uid, userName: reminderChildName(name));
    if (!granted) {
      // Reminders stay scheduled; they just will not be shown until the
      // user enables notifications in system settings.
      logger.w('Notification permission denied after login');
    }
  }

  /// Clears a field's error as soon as the parent edits it.
  void onEmailChanged(String _) {
    emailError.value = null;
    authError.value = null;
  }

  void onPasswordChanged(String _) {
    passwordError.value = null;
    authError.value = null;
  }

  bool _validate() {
    emailError.value = Validators.email(email.text);
    passwordError.value = Validators.passwordPresent(password.text);
    return emailError.value == null && passwordError.value == null;
  }

  Future<void> userLogin() async {
    if (isSubmitting.value) return;
    authError.value = null;
    if (!_validate()) return;

    isSubmitting.value = true;
    try {
      // Trimmed, as v1.0 did on both sign-up and sign-in: every existing
      // account's password was stored trimmed, so sending the raw text would
      // lock out anyone whose keyboard adds a trailing space.
      final String? uid =
          await _signIn(email.text.trim(), password.text.trim());
      if (uid == null || uid.isEmpty) {
        authError.value = "LoginController_login_failed_msg".tr;
        return;
      }
      await _onSignedIn(uid);
      Get.offAllNamed(AppRoutes.mainMenu);
    } on FirebaseAuthException catch (e) {
      authError.value = friendlyFirebaseError(e);
    } catch (e, s) {
      logger.w('Sign-in failed', error: e, stackTrace: s);
      authError.value = friendlyFirebaseError(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  void openForgotPassword() => Get.toNamed(AppRoutes.forgotPassword,
      arguments: email.text.trim().isEmpty ? null : email.text.trim());

  void openSignup() => Get.toNamed(AppRoutes.signup);

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
