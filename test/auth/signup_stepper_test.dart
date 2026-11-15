import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Finds the TextField inside the AppField with [key].
Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  tearDown(Get.reset);

  final DateTime now = DateTime(2027, 3, 10);

  late List<String> created;
  late List<UserModel> saved;
  late List<int> scheduleSizes;
  late int rollbacks;
  late int permissionAsks;

  SignupController put({
    Object? createError,
    Object? saveError,
    bool grant = true,
  }) {
    created = <String>[];
    saved = <UserModel>[];
    scheduleSizes = <int>[];
    rollbacks = 0;
    permissionAsks = 0;
    final c = SignupController(
      clock: () => now,
      createAccount: (e, p) async {
        created.add('$e|$p');
        if (createError != null) throw createError;
        return 'uid-new';
      },
      saveProfile: (u, s) async {
        if (saveError != null) throw saveError;
        saved.add(u);
        scheduleSizes.add(s.length);
      },
      rollbackAccount: () async => rollbacks++,
      onCreated: (_) async {},
      requestPermission: () async {
        permissionAsks++;
        return grant;
      },
    );
    Get.put<SignupController>(c);
    return c;
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('signup_next')));
    await tester.pumpAndSettle();
  }

  Future<void> fillAccount(WidgetTester tester) async {
    await tester.enterText(field('signup_email'), 'parent@example.com');
    await tester.enterText(field('signup_password'), 'secret12');
    await tapNext(tester);
  }

  Future<void> fillBaby(WidgetTester tester, SignupController c) async {
    await tester.enterText(field('signup_name'), 'Lina');
    c.setBirthday(DateTime(2027, 1, 15));
    await tester.tap(find.byKey(const Key('signup_sex_female')));
    await tester.pump();
    await tapNext(tester);
  }

  group('steps', () {
    testWidgets('step 1 validates email and password before moving on',
        (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await tapNext(tester);
      expect(c.step.value, SignupStep.account);
      expect(find.text("Email can't be empty."), findsOneWidget);
      await tester.enterText(field('signup_email'), 'parent@example.com');
      await tester.enterText(field('signup_password'), '123');
      await tapNext(tester);
      expect(c.step.value, SignupStep.account);
      expect(find.text('Use at least 6 characters.'), findsOneWidget);
    });

    testWidgets('step 2 needs a name, a birth date and the sex',
        (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      expect(c.step.value, SignupStep.baby);
      await tapNext(tester);
      expect(c.step.value, SignupStep.baby);
      expect(find.text("Name can't be empty."), findsOneWidget);
      expect(find.text("Date of birth can't be empty."), findsOneWidget);
      expect(find.text('Please choose one.'), findsOneWidget);
    });

    testWidgets('values survive going back and forward', (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      expect(c.step.value, SignupStep.measurements);
      await tester.tap(find.byKey(const Key('signup_back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signup_back')));
      await tester.pumpAndSettle();
      expect(c.step.value, SignupStep.account);
      expect(find.text('parent@example.com'), findsOneWidget);
      await tapNext(tester);
      expect(find.text('Lina'), findsOneWidget);
      expect(c.sex.value, 'female');
    });

    testWidgets('measurements are optional and range-checked', (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      await tester.enterText(field('signup_weight'), '3400');
      await tapNext(tester);
      expect(c.step.value, SignupStep.measurements);
      expect(find.textContaining('between'), findsOneWidget);
      await tester.enterText(field('signup_weight'), '3,4');
      await tapNext(tester);
      expect(c.step.value, SignupStep.reminders);
      expect(c.buildUser('x').weight, '3.4',
          reason: 'stored with a dot and Western digits');
    });

    testWidgets('skip clears the measurements', (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      await tester.enterText(field('signup_weight'), '3.4');
      await tester
          .ensureVisible(find.byKey(const Key('signup_skip_measurements')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signup_skip_measurements')));
      await tester.pumpAndSettle();
      expect(c.step.value, SignupStep.reminders);
      expect(c.weight.text, isEmpty);
    });

    testWidgets('reminders: explained first, permission asked on tap',
        (tester) async {
      final c = put();
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      await tapNext(tester);
      expect(c.step.value, SignupStep.reminders);
      expect(permissionAsks, 0, reason: 'never asked before the explanation');
      expect(find.textContaining('6:00'), findsOneWidget);
      expect(find.textContaining('9:00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('signup_turn_on_reminders')));
      await tester.pumpAndSettle();
      expect(permissionAsks, 1);
      expect(find.byKey(const Key('signup_reminders_on')), findsOneWidget);
      await tapNext(tester);
      expect(c.step.value, SignupStep.summary);
    });

    testWidgets('declining reminders still lets the parent continue',
        (tester) async {
      final c = put(grant: false);
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      await tapNext(tester);
      await tester.tap(find.byKey(const Key('signup_turn_on_reminders')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('signup_reminders_off')), findsOneWidget);
      await tapNext(tester);
      expect(c.step.value, SignupStep.summary);
    });
  });

  group('create account', () {
    Future<SignupController> toSummary(WidgetTester tester,
        {Object? createError, Object? saveError}) async {
      final c = put(createError: createError, saveError: saveError);
      await pumpApp(tester, const SignupView());
      await fillAccount(tester);
      await fillBaby(tester, c);
      await tapNext(tester);
      await tester
          .ensureVisible(find.byKey(const Key('signup_reminders_not_now')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('signup_reminders_not_now')));
      await tester.pumpAndSettle();
      expect(c.step.value, SignupStep.summary);
      return c;
    }

    testWidgets('summary reads back every value with the disclaimer',
        (tester) async {
      await toSummary(tester);
      expect(find.textContaining('parent@example.com'), findsOneWidget);
      expect(find.textContaining('Lina'), findsOneWidget);
      expect(find.text('Girl'), findsOneWidget);
      expect(find.byType(MedicalDisclaimer), findsOneWidget);
    });

    testWidgets('success writes the profile with sex and the schedule',
        (tester) async {
      await toSummary(tester);
      await tapNext(tester);
      expect(created, <String>['parent@example.com|secret12']);
      expect(saved.single.sex, 'female');
      expect(saved.single.birthday, '2027-01-15');
      expect(saved.single.uid, 'uid-new');
      expect(scheduleSizes.single, 10);
      expect(routeStub(AppRoutes.mainMenu), findsOneWidget);
    });

    testWidgets('email in use goes back to step 1 with the error there',
        (tester) async {
      final c = await toSummary(tester,
          createError: FirebaseAuthException(code: 'email-already-in-use'));
      await tapNext(tester);
      expect(c.step.value, SignupStep.account);
      expect(find.text('That email is already registered.'), findsOneWidget);
    });

    testWidgets('weak password goes back to step 1', (tester) async {
      final c = await toSummary(tester,
          createError: FirebaseAuthException(code: 'weak-password'));
      await tapNext(tester);
      expect(c.step.value, SignupStep.account);
      expect(c.passwordError.value, isNotNull);
    });

    testWidgets('offline stays on the summary with a banner', (tester) async {
      final c = await toSummary(tester,
          createError: FirebaseAuthException(code: 'network-request-failed'));
      await tapNext(tester);
      expect(c.step.value, SignupStep.summary);
      expect(find.byKey(const Key('signup_submit_error')), findsOneWidget);
    });

    testWidgets('a failed profile write deletes the new Auth user',
        (tester) async {
      final c = await toSummary(tester,
          saveError:
              FirebaseException(plugin: 'firestore', code: 'unavailable'));
      await tapNext(tester);
      expect(rollbacks, 1);
      expect(c.step.value, SignupStep.summary);
      expect(find.byKey(const Key('signup_submit_error')), findsOneWidget);
    });
  });

  group('layout', () {
    for (final Variant v in mainVariants) {
      testWidgets('every step fits a small screen ($v)', (tester) async {
        final c = put();
        await pumpApp(tester, const SignupView(), variant: v);
        expectNoOverflow(tester);
        await tester.enterText(field('signup_email'), 'parent@example.com');
        await tester.enterText(field('signup_password'), 'secret12');
        await tapNext(tester);
        expectNoOverflow(tester);
        await tester.enterText(field('signup_name'), 'لينا محمد عبد الرحمن');
        c.setBirthday(DateTime(2027, 1, 15));
        c.setSex('male');
        await tapNext(tester);
        expectNoOverflow(tester);
        await tapNext(tester);
        expectNoOverflow(tester);
        await tester.tap(find.byKey(const Key('signup_turn_on_reminders')));
        await tester.pumpAndSettle();
        await tapNext(tester);
        expect(c.step.value, SignupStep.summary);
        expectNoOverflow(tester);
      });
    }

    testWidgets('tap targets and labels on the baby step', (tester) async {
      final handle = tester.ensureSemantics();
      final c = put();
      await pumpApp(tester, const SignupView());
      c.step.value = SignupStep.baby;
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
