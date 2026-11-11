import 'package:baby_vax/app/core/service/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the order steps ran in, and can be made to fail at any one of them,
/// so the ordering guarantees and the partial-failure behaviour are both
/// testable without Firebase.
class _FakeSteps implements AccountDeletionSteps {
  _FakeSteps({this.uid = 'uid_1'}) : email = 'parent@example.com';

  final String? uid;
  final String? email;

  final List<String> calls = <String>[];

  /// Step name -> exception to throw when it runs.
  final Map<String, Object> failures = <String, Object>{};

  String? reauthenticatedWith;
  String? deletedDataForUid;

  @override
  String? get currentUserEmail => email;

  @override
  String? get currentUserId => uid;

  void _run(String name) {
    calls.add(name);
    final Object? failure = failures[name];
    if (failure != null) throw failure;
  }

  @override
  Future<void> reauthenticate(String password) async {
    reauthenticatedWith = password;
    _run('reauthenticate');
  }

  @override
  Future<void> deleteUserData(String uid) async {
    deletedDataForUid = uid;
    _run('deleteUserData');
  }

  @override
  Future<void> cancelReminders() async => _run('cancelReminders');

  @override
  Future<void> deleteAuthUser() async => _run('deleteAuthUser');

  @override
  Future<void> signOutAndClearLocalState() async =>
      _run('signOutAndClearLocalState');
}

void main() {
  group('AccountDeletionService', () {
    test('runs every step in the required order', () async {
      final _FakeSteps steps = _FakeSteps();

      await AccountDeletionService(steps).deleteAccount(password: 'pw');

      expect(steps.calls, <String>[
        'reauthenticate',
        // Firestore data must go before the Auth user: the security rules
        // authorize these writes by request.auth.uid, which disappears with
        // the user, orphaning the documents permanently.
        'deleteUserData',
        'cancelReminders',
        'deleteAuthUser',
        'signOutAndClearLocalState',
      ]);
    });

    test('passes the password and uid through', () async {
      final _FakeSteps steps = _FakeSteps(uid: 'uid_42');

      await AccountDeletionService(steps).deleteAccount(password: 'secret');

      expect(steps.reauthenticatedWith, 'secret');
      expect(steps.deletedDataForUid, 'uid_42');
    });

    test('refuses when nobody is signed in, touching nothing', () async {
      final _FakeSteps steps = _FakeSteps(uid: null);

      await expectLater(
        AccountDeletionService(steps).deleteAccount(password: 'pw'),
        throwsA(isA<AccountDeletionException>().having(
            (AccountDeletionException e) => e.error,
            'error',
            AccountDeletionError.notSignedIn)),
      );
      expect(steps.calls, isEmpty);
    });

    test('refuses when the uid is empty', () async {
      final _FakeSteps steps = _FakeSteps(uid: '');

      await expectLater(
        AccountDeletionService(steps).deleteAccount(password: 'pw'),
        throwsA(isA<AccountDeletionException>()),
      );
      expect(steps.calls, isEmpty);
    });

    test('a wrong password stops before anything is deleted', () async {
      final _FakeSteps steps = _FakeSteps();
      steps.failures['reauthenticate'] =
          AccountDeletionException(AccountDeletionError.wrongPassword);

      await expectLater(
        AccountDeletionService(steps).deleteAccount(password: 'wrong'),
        throwsA(isA<AccountDeletionException>().having(
            (AccountDeletionException e) => e.error,
            'error',
            AccountDeletionError.wrongPassword)),
      );
      // Nothing destructive ran.
      expect(steps.calls, <String>['reauthenticate']);
    });

    test('a Firestore failure leaves the user signed in so they can retry',
        () async {
      final _FakeSteps steps = _FakeSteps();
      steps.failures['deleteUserData'] =
          AccountDeletionException(AccountDeletionError.network);

      await expectLater(
        AccountDeletionService(steps).deleteAccount(password: 'pw'),
        throwsA(isA<AccountDeletionException>()),
      );
      expect(steps.calls, <String>['reauthenticate', 'deleteUserData']);
      expect(steps.calls, isNot(contains('signOutAndClearLocalState')));
    });

    test('reminders are cancelled before the auth user is deleted', () async {
      final _FakeSteps steps = _FakeSteps();

      await AccountDeletionService(steps).deleteAccount(password: 'pw');

      expect(steps.calls.indexOf('cancelReminders'),
          lessThan(steps.calls.indexOf('deleteAuthUser')));
    });

    test('a failure deleting the auth user does not clear local state',
        () async {
      final _FakeSteps steps = _FakeSteps();
      steps.failures['deleteAuthUser'] =
          AccountDeletionException(AccountDeletionError.requiresRecentLogin);

      await expectLater(
        AccountDeletionService(steps).deleteAccount(password: 'pw'),
        throwsA(isA<AccountDeletionException>().having(
            (AccountDeletionException e) => e.error,
            'error',
            AccountDeletionError.requiresRecentLogin)),
      );
      expect(steps.calls, isNot(contains('signOutAndClearLocalState')));
    });
  });
}
