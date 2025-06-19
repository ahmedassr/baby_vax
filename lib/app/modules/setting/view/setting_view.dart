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
            title: "Terms And Conditions",
            icon: Icons.article_outlined,
            onTap: () {},
          ),
          20.sbh,
          AppListTitleItem(
            title: "About US",
            icon: Icons.info_outline,
            onTap: () {},
          ),
          20.sbh,
          AppListTitleItem(
            title: "Log Out",
            icon: Icons.logout,
            onTap: () {},
          )
        ],
      ),
    );
  }
}
