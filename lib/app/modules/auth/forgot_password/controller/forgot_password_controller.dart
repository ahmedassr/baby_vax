import '../../../../core/imports/import_manger.dart';
import '../../../../core/utils/validators.dart';

/// Sends a Firebase password-reset email.
///
/// The success message is the same whether or not the address has an
/// account, and `user-not-found` is treated as success: saying "no account
/// for that email" tells anyone who types an address whether it is
/// registered.
class ForgotPasswordController extends GetxController {
  ForgotPasswordController({
    Future<void> Function(String email)? sendReset,
    String? initialEmail,
  })  : _sendReset = sendReset ?? _firebaseSendReset,
        _initialEmail = initialEmail;

  final Future<void> Function(String email) _sendReset;
  final String? _initialEmail;

  final TextEditingController email = TextEditingController();
  final RxnString emailError = RxnString();
  final RxnString sendError = RxnString();
  final RxBool isSending = false.obs;

  /// The address the link was sent to, once sent.
  final RxnString sentTo = RxnString();

  static Future<void> _firebaseSendReset(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);

  @override
  void onInit() {
    super.onInit();
    // Carries over what the parent already typed on the sign-in screen.
    final Object? arg = _initialEmail ?? Get.arguments;
    if (arg is String) email.text = arg;
  }

  void onEmailChanged(String _) {
    emailError.value = null;
    sendError.value = null;
  }

  Future<void> send() async {
    if (isSending.value) return;
    sendError.value = null;
    emailError.value = Validators.email(email.text);
    if (emailError.value != null) return;

    final String address = email.text.trim();
    isSending.value = true;
    try {
      await _sendReset(address);
      sentTo.value = address;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          sentTo.value = address;
        case 'invalid-email':
          emailError.value = "error_invalid_email_msg".tr;
        default:
          sendError.value = friendlyFirebaseError(e);
      }
    } catch (e) {
      sendError.value = friendlyFirebaseError(e);
    } finally {
      isSending.value = false;
    }
  }

  /// Back to the form, to send to a different address.
  void editEmail() => sentTo.value = null;

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}
