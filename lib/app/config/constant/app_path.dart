import 'package:baby_vax/app/config/session/session_manager.dart';

class AppPath {
  // Collection
  static const String usersColl = 'users';
  static const String medicalDatesColl = 'medical_dates';
  static const String tipsColl = 'tips';
  static const String tipsEnColl = 'tips_en';

  /// v1.1: dated growth measurements.
  static const String measurementsColl = 'measurements';

  /// v1.1: the parent's own reminders and appointments.
  static const String remindersColl = 'reminders';

  // Documents
  static String userDoc(String uid) => '$usersColl/$uid';

  /// The signed-in user's document. With nobody signed in this is
  /// "users/", which FirestoreAccessGuard refuses.
  static String get currentUserDoc =>
      '$usersColl/${SessionManager.signedInUid ?? ''}';
  static String userMedicalDates(String uid) =>
      '${userDoc(uid)}/$medicalDatesColl';

  static String userMeasurements(String uid) =>
      '${userDoc(uid)}/$measurementsColl';
  static String userReminders(String uid) => '${userDoc(uid)}/$remindersColl';

  /// Every subcollection under a user's document. Account deletion walks
  /// this list, since deleting the parent document leaves them behind.
  static List<String> userSubcollections(String uid) => <String>[
        userMedicalDates(uid),
        userMeasurements(uid),
        userReminders(uid),
      ];
}
