import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/app_startup.dart';
import 'package:baby_vax/app/modules/splash/splash_timing.dart';

/// What the splash does besides drawing: decides whether this is the first
/// launch, waits for start-up work, and routes. The animation itself lives
/// in `SplashView`, which needs a `BuildContext` for reduced motion.
class SplashController extends GetxController {
  SplashController({
    bool Function(String key)? readFlag,
    void Function(String key)? setFlag,
    Future<void>? startup,
    void Function(String route)? navigate,
  })  : _readFlag = readFlag ?? _storageRead,
        _setFlag = setFlag ?? _storageSet,
        _startup = startup,
        _navigate = navigate ?? Get.offAllNamed;

  final bool Function(String key) _readFlag;
  final void Function(String key) _setFlag;
  final Future<void>? _startup;
  final void Function(String route) _navigate;

  static bool _storageRead(String key) =>
      AppConstant.getStorage.read(key) ?? false;
  static void _storageSet(String key) =>
      AppConstant.getStorage.write(key, true);

  late final SplashGate gate = SplashGate(onReady: _leave);

  /// True only on the first launch after install.
  late final bool firstLaunch = !_readFlag(StorageKey.hasSeenSplashKey);

  bool isLoggedIn = false;

  @override
  void onInit() {
    super.onInit();
    isLoggedIn = _readFlag(StorageKey.isLoginKey);
    // Written now, not at the end: a launch interrupted mid-animation
    // still counts, so the full version never plays twice.
    if (firstLaunch) _setFlag(StorageKey.hasSeenSplashKey);
    unawaited(_waitForStartup());
  }

  Future<void> _waitForStartup() async {
    await (_startup ?? AppStartup.ready);
    // Top up reminders on every start. Reminders are only scheduled for the
    // next few months (see NotificationCoordinator.horizonMonths), so this
    // is what extends them over the schedule's 15-year span. It also
    // re-reads the device timezone, picking up travel and DST changes, and
    // repairs a state where the OS dropped pending alarms.
    //
    // Deliberately not awaited: routing must not wait on Firestore, and a
    // failure here is logged by the coordinator rather than blocking the
    // user from opening the app.
    if (isLoggedIn) unawaited(_syncReminders());
    gate.markInitDone();
  }

  /// The animation finished; leave as soon as start-up work is done too.
  void onAnimationDone() => gate.markAnimationDone();

  /// A tap on the splash.
  void skip() => gate.skip();

  void _leave() {
    _navigate(nextRoute(
        isLoggedIn: isLoggedIn,
        hasSeenOnboarding: _readFlag(StorageKey.hasSeenOnboardingKey)));
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
    if (!Get.isRegistered<NotificationCoordinator>()) return;

    final String userName =
        reminderChildName(AppConstant.getStorage.read(StorageKey.userNameKey));

    await Get.find<NotificationCoordinator>().onTimeZoneChanged(
      userId: userId,
      userName: userName,
    );
  }
}
