import 'package:baby_vax/app/core/service/account_deletion_service.dart';

import '../../../core/imports/import_manger.dart';
import '../widget/delete_account_dialog.dart';

class SettingsController extends GetxController {
  var isDarkMode = false.obs;
  final RxBool isDeletingAccount = false.obs;
  var currentLanguage = (Get.locale?.languageCode ?? 'en').obs;
  var locale = Get.locale?.languageCode;

  @override
  void onInit() {
    super.onInit();
    loadThemePreference();
    currentLanguage.value = AppConstant.getStorage.read("language") ?? 'en';
  }

  /// Until the user picks a theme the app follows the system, and the
  /// switch shows what the system is using.
  Future<void> loadThemePreference() async {
    final bool? saved = AppConstant.getStorage.read(StorageKey.isDarkModeKey);
    isDarkMode.value = saved ?? Get.isPlatformDarkMode;
    Get.changeThemeMode(AppTheme.themeModeFor(saved));
  }

  Future<void> toggleDarkMode(bool value) async {
    isDarkMode(value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    await AppConstant.getStorage.write(StorageKey.isDarkModeKey, value);
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
          Get.toNamed(AppRoutes.login);
        },
        noAction: () => Get.back()));
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
        yesAction: () => Get.offAllNamed(AppRoutes.login),
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

  Future changeLanguage() async {
    String newLang = currentLanguage.value == "ar" ? "en" : "ar";
    Locale newLocale =
        newLang == "ar" ? const Locale('ar', 'SA') : const Locale('en', 'US');
    Get.updateLocale(newLocale);
    currentLanguage.value = newLang;
    await AppConstant.getStorage.write(StorageKey.languageKey, newLang);
  }
}
