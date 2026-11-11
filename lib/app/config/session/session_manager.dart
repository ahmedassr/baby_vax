import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  /// Cached uid from local storage. It can be stale (for example after the
  /// Firebase session expired), so never use it on its own to decide that
  /// a user is signed in. Use [signedInUid].
  static String uId = "";

  /// Source of the signed-in Firebase user's uid. Replaceable in tests.
  static String? Function() authUid = () {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // Firebase not initialised (unit tests, very early startup).
      return null;
    }
  };

  /// The uid of the signed-in Firebase user, or null when nobody is signed
  /// in.
  static String? get signedInUid {
    final String? uid = authUid();
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  static bool get isSignedIn => signedInUid != null;
}
