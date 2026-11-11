import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> logoScale;
  late Animation<Offset> logoSlide;
  late Animation<double> textOpacity;

  bool isLoggedIn = false;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoggedIn = AppConstant.getStorage.read(StorageKey.isLoginKey) ?? false;

    // Top up reminders on every start. Reminders are only scheduled for the
    // next few months (see NotificationCoordinator.horizonMonths), so this is
    // what extends them over the schedule's 15-year span. It also re-reads the
    // device timezone, picking up travel and DST changes, and repairs a state
    // where the OS dropped pending alarms.
    //
    // Deliberately not awaited: the splash animation and routing must not wait
    // on Firestore, and a failure here is logged by the coordinator rather
    // than blocking the user from opening the app.
    if (isLoggedIn) {
      unawaited(_syncReminders());
    }

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    logoSlide = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    logoScale = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
      ),
    );

    textOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.9, 1, curve: Curves.easeIn),
      ),
    );

    // Route as soon as the intro animation ends. v1.0 waited a fixed four
    // seconds, more than twice the animation, on every cold start.
    animationController.forward().whenComplete(() {
      final bool seen =
          AppConstant.getStorage.read(StorageKey.hasSeenOnboardingKey) ?? false;
      Get.offAllNamed(
          nextRoute(isLoggedIn: isLoggedIn, hasSeenOnboarding: seen));
    });
  }

  /// Where the splash goes: the introduction the very first time, then the
  /// schedule for a signed-in parent and sign-in for everyone else.
  static String nextRoute({
    required bool isLoggedIn,
    required bool hasSeenOnboarding,
  }) {
    if (!hasSeenOnboarding && !isLoggedIn) return AppRoutes.onboarding;
    return isLoggedIn ? AppRoutes.mainMenu : AppRoutes.login;
  }

  /// Re-reads the device timezone and rebuilds reminders from Firestore.
  Future<void> _syncReminders() async {
    final String userId = SessionManager.signedInUid ?? "";
    if (userId.isEmpty) return;

    final String userName =
        reminderChildName(AppConstant.getStorage.read(StorageKey.userNameKey));

    await Get.find<NotificationCoordinator>().onTimeZoneChanged(
      userId: userId,
      userName: userName,
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
