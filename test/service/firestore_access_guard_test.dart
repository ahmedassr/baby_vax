import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/firestore_access_guard.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String alice = 'alice_uid';

  group('FirestoreAccessGuard', () {
    void allowed(String path, String? uid) =>
        expect(() => FirestoreAccessGuard.check(path, uid), returnsNormally);
    void refused(String path, String? uid) => expect(
        () => FirestoreAccessGuard.check(path, uid),
        throwsA(isA<NotSignedInException>()));

    test('a user path needs that user signed in', () {
      allowed('users/$alice', alice);
      allowed('users/$alice/medical_dates', alice);
      allowed('users/$alice/medical_dates/v1', alice);
      allowed('/users/$alice/medical_dates', alice);
      refused('users/$alice', null);
      refused('users/$alice/medical_dates', '');
      refused('users/$alice/medical_dates', 'bob_uid');
    });

    test('an empty uid in the path is always refused', () {
      refused('users/', alice);
      refused('users//medical_dates', alice);
      refused('users//medical_dates', null);
      refused('users', alice);
    });

    test('tips need someone signed in', () {
      for (final coll in ['tips', 'tips_en', 'tips_en/t1']) {
        refused(coll, null);
        refused(coll, '');
        allowed(coll, alice);
      }
    });

    test('a collection merely starting with "tips" is not treated as tips', () {
      allowed('tipsy', null);
    });
  });

  group('SessionManager.signedInUid', () {
    tearDown(() => SessionManager.authUid = () => null);

    test('follows Firebase Auth, not the cached uid', () {
      SessionManager.uId = 'stale_uid';
      SessionManager.authUid = () => null;
      expect(SessionManager.signedInUid, isNull);
      expect(SessionManager.isSignedIn, isFalse);

      SessionManager.authUid = () => alice;
      expect(SessionManager.signedInUid, alice);
      expect(SessionManager.isSignedIn, isTrue);

      SessionManager.authUid = () => '';
      expect(SessionManager.signedInUid, isNull);
      SessionManager.uId = '';
    });

    test('currentUserDoc has no uid when signed out', () {
      SessionManager.authUid = () => null;
      expect(AppPath.currentUserDoc, 'users/');
      expect(() => FirestoreAccessGuard.check(AppPath.currentUserDoc, null),
          throwsA(isA<NotSignedInException>()));
    });
  });

  // These controllers are created at app start, before anyone signs in. No
  // Firestore helper is registered here, so any attempt to read would fail
  // and put the controller in the error state.
  group('controllers before sign-in', () {
    setUp(() {
      Get.testMode = true;
      SessionManager.uId = 'stale_uid';
      SessionManager.authUid = () => null;
    });
    tearDown(() {
      SessionManager.uId = '';
      Get.reset();
    });

    test('HomeController reads nothing', () async {
      final c = HomeController();
      await c.fetchUserData();
      expect(c.status.isError, isFalse);
      expect(c.userDetails.value, isNull);
    });

    test('MedicalDatesController reads nothing', () async {
      final c = MedicalDatesController();
      await c.fetchMedicalDates();
      expect(c.status.isError, isFalse);
    });

    test('TipsController reads nothing', () async {
      final c = TipsController();
      await c.fetchTips();
      expect(c.status.isError, isFalse);
    });
  });
}
