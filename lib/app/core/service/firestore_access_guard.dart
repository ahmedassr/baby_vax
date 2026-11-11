import 'package:baby_vax/app/config/constant/app_path.dart';

/// Thrown instead of sending a request the security rules would deny
/// because nobody (or a different user) is signed in.
class NotSignedInException implements Exception {
  NotSignedInException(this.path);

  final String path;

  @override
  String toString() => 'NotSignedInException: refused $path without sign-in';
}

/// Decides, before any request is sent, whether a Firestore path may be
/// touched by the current session.
///
///   users/{uid}/...   only by the signed-in user with that uid
///   tips, tips_en     only when someone is signed in
///
/// The rules deny these anyway. Checking here means the app never sends the
/// request at all, so there is no PERMISSION_DENIED in the logs and no read
/// with an empty uid ("users//medical_dates").
class FirestoreAccessGuard {
  const FirestoreAccessGuard._();

  static void check(String path, String? signedInUid) {
    final String p = path.startsWith('/') ? path.substring(1) : path;
    final List<String> segments = p.split('/');
    final String root = segments.first;
    final bool hasUser = signedInUid != null && signedInUid.isNotEmpty;

    if (root == AppPath.usersColl) {
      // An empty uid ("users//medical_dates") gives an empty segment, which
      // can never match.
      final String uidInPath = segments.length > 1 ? segments[1] : '';
      if (!hasUser || uidInPath != signedInUid) {
        throw NotSignedInException(path);
      }
      return;
    }

    if (root == AppPath.tipsColl || root == AppPath.tipsEnColl) {
      if (!hasUser) throw NotSignedInException(path);
    }
  }
}
