import 'package:baby_vax/app/config/session/session_manager.dart';

class AppPath {
  // Collection
  static const String usersColl = 'users';
  static const String medicalDatesColl = 'medical_dates';
  static const String tipsColl = 'tips';
  static const String tipsEnColl = 'tips_en';

  // Documents
  static String userDoc(String uid) => '$usersColl/$uid';

  /// The signed-in user's document. With nobody signed in this is
  /// "users/", which FirestoreAccessGuard refuses.
  static String get currentUserDoc =>
      '$usersColl/${SessionManager.signedInUid ?? ''}';
  static String userMedicalDates(String uid) =>
      '${userDoc(uid)}/$medicalDatesColl';
}
