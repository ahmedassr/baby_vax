import 'dart:async';
import 'dart:io';

import 'package:baby_vax/app/core/imports/import_library.dart';

/// Turns a Firebase or network failure into a localized, friendly message.
///
/// This used to substring-match `error.toString()` against English fragments
/// and return hardcoded English. That was fragile — the matched text is not API
/// and changes between plugin versions — and it meant Arabic users saw English
/// errors. It also had no case for the failures users actually hit most:
/// being offline, a Firestore permission denial, or an expired token.
///
/// Matching is on `FirebaseException.code`, which is stable and documented.
String friendlyFirebaseError(Object error) {
  if (error is FirebaseAuthException) {
    return _authMessage(error.code);
  }
  if (error is FirebaseException) {
    return _firestoreMessage(error.code);
  }
  // Not a Firebase error: most often no connectivity at all.
  if (error is SocketException || error is TimeoutException) {
    return "error_offline_msg".tr;
  }
  return "error_generic_msg".tr;
}

String _authMessage(String code) {
  switch (code) {
    case 'email-already-in-use':
      return "error_email_already_in_use_msg".tr;
    case 'invalid-email':
      return "error_invalid_email_msg".tr;
    case 'weak-password':
      return "error_weak_password_msg".tr;
    case 'network-request-failed':
      return "error_offline_msg".tr;
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-not-found':
      // Deliberately the same message for all three: saying which one was
      // wrong tells an attacker whether an email is registered.
      return "error_invalid_credentials_msg".tr;
    case 'user-disabled':
      return "error_user_disabled_msg".tr;
    case 'too-many-requests':
      return "error_too_many_requests_msg".tr;
    case 'requires-recent-login':
    case 'user-token-expired':
      return "error_session_expired_msg".tr;
    case 'operation-not-allowed':
      return "error_generic_msg".tr;
    default:
      return "error_generic_msg".tr;
  }
}

String _firestoreMessage(String code) {
  switch (code) {
    case 'unavailable':
    case 'deadline-exceeded':
      // Firestore reports this when it cannot reach the backend. Reads still
      // come from the local cache, so the app itself keeps working.
      return "error_offline_msg".tr;
    case 'permission-denied':
      return "error_permission_denied_msg".tr;
    case 'unauthenticated':
      return "error_session_expired_msg".tr;
    case 'not-found':
      return "error_not_found_msg".tr;
    case 'resource-exhausted':
      return "error_too_many_requests_msg".tr;
    case 'failed-precondition':
      // Usually a missing Firestore index. Users cannot act on that, so they
      // get the generic message; the detail is in the logs and Crashlytics.
      return "error_generic_msg".tr;
    default:
      return "error_generic_msg".tr;
  }
}
