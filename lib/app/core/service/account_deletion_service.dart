import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Why the account could not be deleted, so the UI can say something useful
/// instead of a generic failure.
enum AccountDeletionError {
  /// The password did not match.
  wrongPassword,

  /// Firebase wants a fresh sign-in before it will accept the deletion.
  requiresRecentLogin,

  /// Network or Firestore failure.
  network,

  /// Nobody is signed in.
  notSignedIn,

  unknown,
}

class AccountDeletionException implements Exception {
  AccountDeletionException(this.error, [this.cause]);

  final AccountDeletionError error;
  final Object? cause;

  @override
  String toString() => 'AccountDeletionException($error): $cause';
}

/// The individual steps of account deletion, behind an interface so the
/// ordering and failure handling can be tested without Firebase.
abstract class AccountDeletionSteps {
  /// Email of the signed-in user, or null when nobody is signed in.
  String? get currentUserEmail;

  /// Uid of the signed-in user, or null when nobody is signed in.
  String? get currentUserId;

  /// Proves the password before anything destructive happens.
  Future<void> reauthenticate(String password);

  /// Removes the user's Firestore documents, subcollections included.
  Future<void> deleteUserData(String uid);

  /// Clears every scheduled local reminder.
  Future<void> cancelReminders();

  /// Deletes the Firebase Auth user.
  Future<void> deleteAuthUser();

  /// Signs out and clears local storage and session state.
  Future<void> signOutAndClearLocalState();
}

/// Deletes a user's account and everything belonging to it.
///
/// Required by Google Play's account-deletion policy for any app that lets
/// users create an account.
///
/// The order is deliberate:
///   1. re-authenticate — Firebase requires recent credentials, and it also
///      stops someone with a borrowed unlocked phone from wiping the data;
///   2. delete Firestore data — must happen **before** the Auth user goes,
///      because the security rules authorize these writes by
///      `request.auth.uid`, and once the user is deleted that is gone and the
///      documents would be orphaned permanently;
///   3. cancel reminders — otherwise the phone keeps firing notifications for
///      a child whose data no longer exists;
///   4. delete the Auth user;
///   5. sign out and clear local state.
class AccountDeletionService {
  AccountDeletionService(this._steps);

  final AccountDeletionSteps _steps;

  /// Runs the deletion. Throws [AccountDeletionException] on failure, having
  /// made no partial change it could avoid.
  Future<void> deleteAccount({required String password}) async {
    final String? uid = _steps.currentUserId;
    if (uid == null || uid.isEmpty) {
      throw AccountDeletionException(AccountDeletionError.notSignedIn);
    }

    // 1. Prove identity first. Nothing destructive has happened yet, so a
    // wrong password is a clean no-op.
    await _steps.reauthenticate(password);

    // 2. Firestore data, while the credentials still authorize it.
    await _steps.deleteUserData(uid);

    // 3. Local reminders.
    await _steps.cancelReminders();

    // 4. The Auth user itself.
    await _steps.deleteAuthUser();

    // 5. Local state. Done last so a failure above leaves the user signed in
    // and able to retry rather than stranded in a half-deleted state.
    await _steps.signOutAndClearLocalState();

    logger.i('Account deleted');
  }
}

/// Real implementation against Firebase, Firestore, the reminder coordinator
/// and local storage.
class FirebaseAccountDeletionSteps implements AccountDeletionSteps {
  @override
  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> reauthenticate(String password) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw AccountDeletionException(AccountDeletionError.notSignedIn);
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(_mapAuthError(e), e);
    } catch (e) {
      throw AccountDeletionException(AccountDeletionError.unknown, e);
    }
  }

  @override
  Future<void> deleteUserData(String uid) async {
    try {
      // Subcollections first: deleting the parent document does not remove
      // them, and after the parent is gone they are much harder to find.
      for (final String path in AppPath.userSubcollections(uid)) {
        await AppConstant.fireStoreHelper1.deleteCollection(path: path);
      }
      await AppConstant.fireStoreHelper1.deleteDocument(AppPath.userDoc(uid));
    } on FirebaseException catch (e) {
      throw AccountDeletionException(AccountDeletionError.network, e);
    } catch (e) {
      throw AccountDeletionException(AccountDeletionError.unknown, e);
    }
  }

  @override
  Future<void> cancelReminders() async {
    await Get.find<NotificationCoordinator>().cancelAllReminders();
  }

  @override
  Future<void> deleteAuthUser() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AccountDeletionException(_mapAuthError(e), e);
    } catch (e) {
      throw AccountDeletionException(AccountDeletionError.unknown, e);
    }
  }

  @override
  Future<void> signOutAndClearLocalState() async {
    await FirebaseAuth.instance.signOut();
    SessionManager.uId = "";
    // No cached uid, child name or login flag may survive a deletion. Device
    // preferences (language, theme, onboarding seen) are not about the
    // account and are kept.
    await AppConstant.getStorage.clearUserData();
  }

  static AccountDeletionError _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return AccountDeletionError.wrongPassword;
      case 'requires-recent-login':
        return AccountDeletionError.requiresRecentLogin;
      case 'network-request-failed':
        return AccountDeletionError.network;
      default:
        return AccountDeletionError.unknown;
    }
  }
}
