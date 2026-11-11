import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';

/// Settings, grouped: appearance, language, reminders, about, account.
///
/// v1.0 had five unrelated rows 20dp apart, two of which ("Terms and
/// Conditions", "About us") did nothing when tapped.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      children: <Widget>[
        AppSectionHeader(title: "Settings_appearance".tr),
        Obx(() => Row(
              children: <Widget>[
                for (final (ThemeMode mode, String key, IconData icon)
                    in <(ThemeMode, String, IconData)>[
                  (
                    ThemeMode.system,
                    "Settings_theme_system",
                    Icons.brightness_auto_rounded
                  ),
                  (
                    ThemeMode.light,
                    "AppSettingDarkModeSwitch_light_mode_label",
                    Icons.light_mode_rounded
                  ),
                  (
                    ThemeMode.dark,
                    "AppSettingDarkModeSwitch_dark_mode_label",
                    Icons.dark_mode_rounded
                  ),
                ]) ...<Widget>[
                  if (mode != ThemeMode.system)
                    const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppChoiceTile(
                      key: Key('theme_${mode.name}'),
                      label: key.tr,
                      icon: icon,
                      selected: controller.themeMode.value == mode,
                      onTap: () => controller.setThemeMode(mode),
                    ),
                  ),
                ],
              ],
            )),
        AppSectionHeader(title: "SettingsView_language_label".tr),
        Obx(() => AppListGroup(children: <Widget>[
              for (final (String code, String label)
                  in const <(String, String)>[
                ('ar', 'العربية'),
                ('en', 'English'),
              ])
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  selected: controller.currentLanguage.value == code,
                  child: AppListRow(
                    key: Key('language_$code'),
                    title: label,
                    onTap: () => controller.changeLanguage(code),
                    trailing: controller.currentLanguage.value == code
                        ? Icon(Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary)
                        : const SizedBox.square(dimension: 24),
                  ),
                ),
            ])),
        AppSectionHeader(title: "Signup_step_reminders".tr),
        Obx(() => AppListGroup(children: <Widget>[
              AppListRow(
                key: const Key('settings_notifications'),
                icon: controller.notificationsOn.value
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                title: "Settings_notifications".tr,
                subtitle: "Settings_notifications_hint".tr,
                value: controller.notificationsOn.value
                    ? "reminders_on_label".tr
                    : "reminders_off_label".tr,
                onTap: controller.openNotificationSettings,
              ),
            ])),
        AppSectionHeader(title: "Settings_about".tr),
        AppListGroup(children: <Widget>[
          AppListRow(
            key: const Key('settings_about'),
            icon: Icons.info_outline_rounded,
            title: "Settings_about_app".tr,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Baby Vax',
              applicationIcon: const AppLogo(size: 48),
              children: <Widget>[
                const SizedBox(height: AppSpacing.md),
                Text("MedicalDisclaimer_body".tr),
                const SizedBox(height: AppSpacing.sm),
                Text("MedicalDisclaimer_source".tr),
              ],
            ),
          ),
        ]),
        AppSectionHeader(title: "Signup_step_account".tr),
        AppListGroup(children: <Widget>[
          AppListRow(
            key: const Key('settings_logout'),
            icon: Icons.logout_rounded,
            title: "SettingsView_logout_label".tr,
            onTap: controller.onLogout,
          ),
          // Required by Google Play's account-deletion policy: an app that
          // lets users create an account must let them delete it in-app.
          Obx(() => AppListRow(
                key: const Key('settings_delete'),
                icon: Icons.delete_forever_outlined,
                title: "SettingsView_delete_account_label".tr,
                destructive: true,
                trailing: controller.isDeletingAccount.value
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: controller.isDeletingAccount.value
                    ? null
                    : controller.onDeleteAccount,
              )),
        ]),
      ],
    );
  }
}
