import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/onboarding/controller/onboarding_controller.dart';
import 'package:baby_vax/app/modules/onboarding/view/onboarding_view.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  group('splash routing', () {
    test('first launch goes to the introduction', () {
      expect(
          SplashController.nextRoute(
              isLoggedIn: false, hasSeenOnboarding: false),
          AppRoutes.onboarding);
    });

    test('after the introduction, signed-out goes to sign-in', () {
      expect(
          SplashController.nextRoute(
              isLoggedIn: false, hasSeenOnboarding: true),
          AppRoutes.login);
    });

    test('a signed-in parent never sees the introduction', () {
      // An existing v1.0 user has no "seen" flag; they must go straight to
      // their schedule after the update.
      expect(
          SplashController.nextRoute(
              isLoggedIn: true, hasSeenOnboarding: false),
          AppRoutes.mainMenu);
      expect(
          SplashController.nextRoute(isLoggedIn: true, hasSeenOnboarding: true),
          AppRoutes.mainMenu);
    });
  });

  group('device preferences survive logout', () {
    test('the onboarding, language and theme keys are device preferences', () {
      expect(StorageKey.devicePreferences,
          contains(StorageKey.hasSeenOnboardingKey));
      expect(StorageKey.devicePreferences, contains(StorageKey.languageKey));
      expect(StorageKey.devicePreferences, contains(StorageKey.isDarkModeKey));
      expect(StorageKey.devicePreferences, isNot(contains(StorageKey.uidKey)));
      expect(
          StorageKey.devicePreferences, isNot(contains(StorageKey.isLoginKey)));
      expect(StorageKey.devicePreferences,
          isNot(contains(StorageKey.userNameKey)));
    });
  });

  group('OnboardingView', () {
    late Map<String, bool> saved;

    OnboardingController put() {
      saved = <String, bool>{};
      final c = OnboardingController(save: (k, v) async => saved[k] = v);
      Get.put<OnboardingController>(c);
      return c;
    }

    for (final Variant v in mainVariants) {
      testWidgets('every page fits a small screen ($v)', (tester) async {
        final c = put();
        await pumpApp(tester, const OnboardingView(), variant: v);
        for (int i = 0; i < OnboardingController.pages.length; i++) {
          expect(find.text(OnboardingController.pages[i].titleKey.tr),
              findsOneWidget);
          expectNoOverflow(tester);
          if (i < OnboardingController.pages.length - 1) {
            // Not awaited: the page animation only advances as the test
            // pumps frames.
            c.next();
            await tester.pumpAndSettle();
          }
        }
        expect(find.text('Onboarding_get_started'.tr), findsOneWidget);
      });
    }

    testWidgets('Next walks the pages, Get started saves and leaves',
        (tester) async {
      put();
      await pumpApp(tester, const OnboardingView());
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(saved, isEmpty);
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
      expect(saved[StorageKey.hasSeenOnboardingKey], isTrue);
      expect(routeStub(AppRoutes.login), findsOneWidget);
    });

    testWidgets('Skip saves straight away', (tester) async {
      put();
      await pumpApp(tester, const OnboardingView());
      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle();
      expect(saved[StorageKey.hasSeenOnboardingKey], isTrue);
      expect(routeStub(AppRoutes.login), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pumpApp(tester, const OnboardingView());
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
