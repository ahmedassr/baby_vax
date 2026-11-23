import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';

/// One page of the first-launch introduction.
class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;
}

/// The first-launch introduction: three short pages, skippable, shown once.
///
/// "Seen" is stored in [StorageKey.hasSeenOnboardingKey], which is a device
/// preference and survives logout (see `GetStorageService.clearUserData`).
class OnboardingController extends GetxController {
  OnboardingController({Future<void> Function(String key, bool value)? save})
      : _save = save ?? _saveToStorage;

  final Future<void> Function(String key, bool value) _save;

  static Future<void> _saveToStorage(String key, bool value) =>
      AppConstant.getStorage.write(key, value);

  /// The pages, in order. No medical claims: what the app does, not what
  /// vaccines do.
  static const List<OnboardingPage> pages = <OnboardingPage>[
    OnboardingPage(
      icon: Icons.event_available_rounded,
      titleKey: "Onboarding_schedule_title",
      bodyKey: "Onboarding_schedule_body",
    ),
    OnboardingPage(
      icon: Icons.notifications_active_rounded,
      titleKey: "Onboarding_reminders_title",
      bodyKey: "Onboarding_reminders_body",
    ),
    OnboardingPage(
      icon: Icons.assignment_turned_in_rounded,
      titleKey: "Onboarding_record_title",
      bodyKey: "Onboarding_record_body",
    ),
  ];

  final PageController pageController = PageController();
  final RxInt page = 0.obs;

  bool get isLast => page.value == pages.length - 1;

  void onPageChanged(int index) {
    page.value = index;
    AppHaptics.selection();
  }

  /// Next page, or finish on the last one.
  Future<void> next() async {
    if (isLast) return finish();
    await pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Marks the introduction as seen and goes to sign-in. Also what Skip does.
  Future<void> finish() async {
    await _save(StorageKey.hasSeenOnboardingKey, true);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
