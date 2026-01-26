import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/setting/widget/app_setting_dark_mode_switch.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut<SettingsController>(() => SettingsController());
    return Padding(
      padding: AppConstant.columnPadding,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AppSettingDarkModeSwitch(controller: controller),
          20.sbh,
          AppListTitleItem(
            title: "SettingsView_language_label".tr,
            additionalTitle: controller.currentLanguage.value.toUpperCase(),
            icon: Icons.language,
            onTap: () {
              Get.bottomSheet(
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(text: "SettingsView_select_language".tr, style: AppTextStyles.titleMedium),
                      20.sbh,
                      ListTile(
                        title: const Text("العربية"),
                        trailing: controller.currentLanguage.value == 'ar' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                        onTap: () {
                          controller.changeLanguage();
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: const Text("English"),
                        trailing: controller.currentLanguage.value == 'en' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
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
          ),
          20.sbh,
          AppListTitleItem(
            title: "SettingsView_terms_and_conditions_label".tr,
            icon: Icons.article_outlined,
            onTap: () {},
          ),
          20.sbh,
          AppListTitleItem(
            title: "SettingsView_about_us_label".tr,
            icon: Icons.info_outline,
            onTap: () {},
          ),
          20.sbh,
          AppListTitleItem(
            title: "SettingsView_logout_label".tr,
            icon: Icons.logout,
            onTap: controller.onLogout,
          )
        ],
      ),
    );
  }
}
