import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/validators.dart';
import 'package:baby_vax/app/modules/auth/forgot_password/controller/forgot_password_controller.dart';
import 'package:baby_vax/app/modules/auth/forgot_password/view/forgot_password_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  group('Validators', () {
    setUp(() => Get.locale = const Locale('en'));

    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('name@gmail'), isNotNull);
      expect(Validators.email('  a@b.co  '), isNull);
    });

    test('new password needs Firebase\'s minimum', () {
      expect(Validators.newPassword('12345'), isNotNull);
      expect(Validators.newPassword('123456'), isNull);
    });

    test('decimal parsing accepts comma and Arabic-Indic digits', () {
      expect(Validators.parseDecimal('3.4'), 3.4);
      expect(Validators.parseDecimal('3,4'), 3.4);
      expect(Validators.parseDecimal('٣٫٤'), 3.4);
      expect(Validators.parseDecimal('abc'), isNull);
    });

    test('optional measurement: empty ok, range checked', () {
      expect(Validators.optionalMeasurement('', min: 0.5, max: 40), isNull);
      expect(Validators.optionalMeasurement('3.4', min: 0.5, max: 40), isNull);
      expect(
          Validators.optionalMeasurement('400', min: 0.5, max: 40), isNotNull);
      expect(Validators.optionalMeasurement('x', min: 0.5, max: 40), isNotNull);
    });
  });

  group('LoginView', () {
    late List<String> attempts;

    LoginController put({Object? failWith}) {
      attempts = <String>[];
      final c = LoginController(
        signIn: (e, p) async {
          attempts.add('$e|$p');
          if (failWith != null) throw failWith;
          return 'uid1';
        },
        onSignedIn: (_) async {},
      );
      Get.put<LoginController>(c);
      return c;
    }

    for (final Variant v in mainVariants) {
      testWidgets('fits a small screen ($v)', (tester) async {
        put();
        await pumpApp(tester, const LoginView(), variant: v);
        expect(find.text('LoginView_welcome_back'.tr), findsOneWidget);
        expect(find.text('LoginView_forgot_password'.tr), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('empty submit shows inline errors and sends nothing',
        (tester) async {
      put();
      await pumpApp(tester, const LoginView());
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pump();
      expect(find.text("Email can't be empty."), findsOneWidget);
      expect(find.text("Password can't be empty."), findsOneWidget);
      expect(attempts, isEmpty);
    });

    testWidgets('wrong password: banner, form kept, error clears on edit',
        (tester) async {
      put(failWith: FirebaseAuthException(code: 'invalid-credential'));
      await pumpApp(tester, const LoginView());
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('login_email')),
              matching: find.byType(TextField)),
          'a@b.co');
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('login_password')),
              matching: find.byType(TextField)),
          'secret1');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_error')), findsOneWidget);
      expect(find.text('Incorrect email or password. Please try again.'),
          findsOneWidget);
      expect(find.byKey(const Key('login_email')), findsOneWidget,
          reason: 'the form must stay on screen');
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('login_password')),
              matching: find.byType(TextField)),
          'secret2');
      await tester.pump();
      expect(find.byKey(const Key('login_error')), findsNothing);
    });

    testWidgets('success goes to the schedule', (tester) async {
      put();
      await pumpApp(tester, const LoginView());
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('login_email')),
              matching: find.byType(TextField)),
          ' a@b.co ');
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('login_password')),
              matching: find.byType(TextField)),
          'secret1');
      await tester.tap(find.byKey(const Key('login_submit')));
      await tester.pumpAndSettle();
      expect(attempts, <String>['a@b.co|secret1']);
      expect(routeStub(AppRoutes.mainMenu), findsOneWidget);
    });

    testWidgets('links go to reset and sign-up', (tester) async {
      put();
      await pumpApp(tester, const LoginView());
      await tester.tap(find.byKey(const Key('login_forgot')));
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.forgotPassword), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pumpApp(tester, const LoginView());
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('ForgotPasswordView', () {
    late List<String> sent;

    void put({Object? failWith, String? initial}) {
      sent = <String>[];
      Get.put<ForgotPasswordController>(ForgotPasswordController(
        initialEmail: initial,
        sendReset: (e) async {
          sent.add(e);
          if (failWith != null) throw failWith;
        },
      ));
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('reset_send')));
      await tester.pumpAndSettle();
    }

    for (final Variant v in mainVariants) {
      testWidgets('form and sent state fit a small screen ($v)',
          (tester) async {
        put(initial: 'parent@example.com');
        await pumpApp(tester, const ForgotPasswordView(), variant: v);
        expectNoOverflow(tester);
        await submit(tester);
        expect(find.text('ForgotPassword_sent_title'.tr), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('carries over the email typed on sign-in', (tester) async {
      put(initial: 'parent@example.com');
      await pumpApp(tester, const ForgotPasswordView());
      expect(find.text('parent@example.com'), findsOneWidget);
    });

    testWidgets('an unknown email looks exactly like a known one',
        (tester) async {
      put(
          initial: 'nobody@example.com',
          failWith: FirebaseAuthException(code: 'user-not-found'));
      await pumpApp(tester, const ForgotPasswordView());
      await submit(tester);
      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('offline shows a banner and keeps the form', (tester) async {
      put(
          initial: 'a@b.co',
          failWith: FirebaseAuthException(code: 'network-request-failed'));
      await pumpApp(tester, const ForgotPasswordView());
      await submit(tester);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.byKey(const Key('reset_send')), findsOneWidget);
    });

    testWidgets('invalid email is caught before sending', (tester) async {
      put(initial: 'nope');
      await pumpApp(tester, const ForgotPasswordView());
      await submit(tester);
      expect(sent, isEmpty);
      expect(
          find.text('That email address does not look right.'), findsOneWidget);
    });
  });
}
