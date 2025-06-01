import 'package:baby_vax/app/core/widget/app_bottom_navigation_bar.dart';
import 'package:baby_vax/app/core/widget/custom_app_bar.dart';

import '../../../core/imports/import_manger.dart';

class MainMenuView extends GetView<MainMenuController> {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: controller.item[controller.currentIndex.value].title,
            showBackButton: false,
            elevation: 8,
          ),
          bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: controller.currentIndex.value,
              elevation: 10,
              items: controller.item
                  .map((item) => BottomNavigationBarItem(
                      icon: Icon(
                        item.icon,
                        size: 26,
                      ),
                      label: item.title))
                  .toList(),
              onTap: (value) => controller.changeValue(value)),
          body: controller.item[controller.currentIndex.value].view,
        ));
  }
}
