import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return AppListTitleItem(
      title: "SettingsView_language_label".tr,
      additionalTitle: controller.currentLanguage.value.toUpperCase(),
      icon: Icons.language,
      onTap: () {
        Get.bottomSheet(
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                    text: "SettingsView_select_language".tr,
                    style: AppTextStyles.titleMedium),
                20.sbh,
                ListTile(
                  title: const Text("العربية"),
                  trailing: controller.currentLanguage.value == 'ar'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.changeLanguage();
                    Get.back();
                  },
                ),
                ListTile(
                  title: const Text("English"),
                  trailing: controller.currentLanguage.value == 'en'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.changeLanguage();
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
