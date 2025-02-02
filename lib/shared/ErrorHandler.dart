class ErrorHandler {
  static String getNiceErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'البريد الاكتروني مستخدم بالفعل';
    } else if (error.contains('invalid-email')) {
      return 'البريد الاكتروني غير صحيح';
    } else if (error.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جدا ';
    } else if (error.contains('network-request-failed')) {
      return 'رجاء تحقق من اتصال الانترنت وحاول مرة اخرى ';
    } else if (error.contains('The supplied auth credential is incorrect')) {
      return 'البريد الالكتروني أو كلمة المرور ليست صحيحة';
    } else {
      return 'هناك خطا ما حاول مرة اخرى';
    }
  }
}
