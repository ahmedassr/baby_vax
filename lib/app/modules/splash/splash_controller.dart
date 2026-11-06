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
      duration: const Duration(milliseconds: 1600),
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


    animationController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      Get.offAllNamed(
        isLoggedIn ? AppRoutes.mainMenu : AppRoutes.login,
      );
    });
  }

  /// Re-reads the device timezone and rebuilds reminders from Firestore.
  Future<void> _syncReminders() async {
    final String userId = SessionManager.uId;
    if (userId.isEmpty) return;

    final String userName =
        AppConstant.getStorage.read(StorageKey.userNameKey) ?? "Your baby";

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
