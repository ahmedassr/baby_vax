import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';

class AppSettingDarkModeSwitch extends StatelessWidget {
  final SettingsController controller;

  const AppSettingDarkModeSwitch({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Obx(() => SwitchListTile(
          title: AppText(
            text: "AppSettingDarkModeSwitch_dark_mode_label".tr,
            style: AppTextStyles.bodyMedium.copyWith(
                color: context.isDarkMode ? Colors.white : Colors.black),
          ),
          secondary: Icon(
            controller.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
            color: controller.isDarkMode.value
                ? AppColors.warning
                : AppColors.primary,
          ),
          value: controller.isDarkMode.value,
          onChanged: controller.toggleDarkMode)),
    );
  }
}
