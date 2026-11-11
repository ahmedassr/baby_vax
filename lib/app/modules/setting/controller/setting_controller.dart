import 'package:baby_vax/app/core/service/account_deletion_service.dart';

import '../../../core/imports/import_manger.dart';
import '../../../core/notification/data/notification_settings_opener.dart';
import '../../../core/utils/app_haptics.dart';
import '../../home/controller/home_controller.dart';
import '../../tips/controller/tips_controller.dart';
import '../widget/delete_account_dialog.dart';

/// Appearance, language, reminders, about, and the account actions.
class SettingsController extends GetxController {
  SettingsController({
    Future<void> Function(String key, dynamic value)? write,
    void Function(String key)? remove,
    Future<bool> Function()? notificationsEnabled,
    NotificationSettingsOpener settingsOpener =
        const NotificationSettingsOpener(),
    Future<void> Function(Locale locale)? applyLocale,
  })  : _write = write ?? _storageWrite,
        _applyLocale = applyLocale ?? Get.updateLocale,
        _remove = remove ?? _storageRemove,
        _notificationsEnabled =
            notificationsEnabled ?? _coordinatorNotificationsEnabled,
        _settingsOpener = settingsOpener;

  final Future<void> Function(String key, dynamic value) _write;
  final void Function(String key) _remove;
  final Future<bool> Function() _notificationsEnabled;
  final NotificationSettingsOpener _settingsOpener;
  final Future<void> Function(Locale locale) _applyLocale;

  static Future<void> _storageWrite(String key, dynamic value) =>
      AppConstant.getStorage.write(key, value);
  static void _storageRemove(String key) => AppConstant.getStorage.remove(key);

  static Future<bool> _coordinatorNotificationsEnabled() async {
    if (!Get.isRegistered<NotificationCoordinator>()) return true;
    return Get.find<NotificationCoordinator>().notificationsEnabled();
  }

  /// System, light or dark. v1.0 had only a light/dark switch, so a parent
  /// who had once touched it could never go back to following the system.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  final RxBool isDeletingAccount = false.obs;

  /// "en" or "ar".
  final RxString currentLanguage = (Get.locale?.languageCode ?? 'en').obs;

  /// Whether reminders can be shown (OS notification setting).
  final RxBool notificationsOn = true.obs;

  @override
  void onInit() {
    super.onInit();
    final bool? saved = _readDarkMode();
    themeMode.value = AppTheme.themeModeFor(saved);
    currentLanguage.value = Get.locale?.languageCode ?? 'en';
    refreshNotificationStatus();
  }

  static bool? _readDarkMode() {
    try {
      return AppConstant.getStorage.read(StorageKey.isDarkModeKey) as bool?;
    } catch (_) {
      // Storage not registered (widget tests).
      return null;
    }
  }

  Future<void> refreshNotificationStatus() async {
    try {
      notificationsOn.value = await _notificationsEnabled();
    } catch (_) {
      notificationsOn.value = true;
    }
  }

  Future<void> openNotificationSettings() async {
    await _settingsOpener.open();
  }

  /// Stores the choice: nothing for "system", so the app keeps following
  /// the phone; a bool for light or dark.
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    AppHaptics.selection();
    if (mode == ThemeMode.system) {
      _remove(StorageKey.isDarkModeKey);
    } else {
      await _write(StorageKey.isDarkModeKey, mode == ThemeMode.dark);
    }
  }

  /// Switches to [lang] ("en" or "ar"). v1.0's version toggled whatever
  /// was current, so tapping "English" while in English switched to Arabic.
  Future<void> changeLanguage(String lang) async {
    if (lang == currentLanguage.value) return;
    currentLanguage.value = lang;
    await _applyLocale(Locale(lang));
    await _write(StorageKey.languageKey, lang);
    // Tips come from a per-language collection.
    if (Get.isRegistered<TipsController>()) {
      Get.find<TipsController>().fetchTips();
    }
  }

  void onLogout() {
    AppConstant.alertService.showAlert(AlertModel.attention(
        message: "SettingsController_logout_alert_msg".tr,
        yesAction: () async {
          await AppConstant.getStorage.write(StorageKey.isLoginKey, false);
          // A signed-out device must not keep notifying about a child's
          // schedule.
          await Get.find<NotificationCoordinator>().cancelAllReminders();
          await FirebaseAuth.instance.signOut();
          SessionManager.uId = "";
          await AppConstant.getStorage.clearUserData();
          // The tabs' controllers are permanent; drop the signed-out
          // parent's data so the next account never sees it, even briefly.
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().clearSession();
          }
          if (Get.isRegistered<MedicalDatesController>()) {
            Get.find<MedicalDatesController>().doses.clear();
          }
          // Replace the stack, so Back cannot return to the signed-in tabs.
          Get.offAllNamed(AppRoutes.login);
        },
        // The dialog closes itself. v1.0 also called Get.back() here, which
        // closed the screen behind the dialog as well.
        noAction: () {}));
  }

  /// Play policy requires an in-app way to delete the account and its data.
  ///
  /// The heavy lifting is in [AccountDeletionService]; this method only drives
  /// the dialog and turns failures into localized messages.
  Future<void> onDeleteAccount({AccountDeletionService? service}) async {
    final String? password = await Get.dialog<String>(
      const DeleteAccountDialog(),
      barrierDismissible: false,
    );

    // Null means the user backed out.
    if (password == null || password.isEmpty) return;

    isDeletingAccount.value = true;
    try {
      final AccountDeletionService deletion =
          service ?? AccountDeletionService(FirebaseAccountDeletionSteps());
      await deletion.deleteAccount(password: password);

      AppConstant.alertService.showAlert(AlertModel.success(
        message: "DeleteAccount_success_msg".tr,
        yesAction: () {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().clearSession();
          }
          Get.offAllNamed(AppRoutes.login);
        },
      ));
    } on AccountDeletionException catch (e) {
      logger.w('Account deletion failed: ${e.error}', error: e.cause);
      AppConstant.alertService
          .showError(message: deletionErrorMessage(e.error));
    } catch (e, s) {
      logger.e('Account deletion failed unexpectedly', error: e, stackTrace: s);
      AppConstant.alertService
          .showError(message: "DeleteAccount_unknown_error_msg".tr);
    } finally {
      isDeletingAccount.value = false;
    }
  }

  /// Maps a failure reason to its localized message. Separated out so the
  /// mapping is testable without Firebase.
  static String deletionErrorMessage(AccountDeletionError error) {
    switch (error) {
      case AccountDeletionError.wrongPassword:
        return "DeleteAccount_wrong_password_msg".tr;
      case AccountDeletionError.requiresRecentLogin:
        return "DeleteAccount_requires_recent_login_msg".tr;
      case AccountDeletionError.network:
        return "DeleteAccount_network_error_msg".tr;
      case AccountDeletionError.notSignedIn:
        return "DeleteAccount_not_signed_in_msg".tr;
      case AccountDeletionError.unknown:
        return "DeleteAccount_unknown_error_msg".tr;
    }
  }
}
