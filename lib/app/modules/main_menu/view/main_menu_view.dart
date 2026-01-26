import 'package:baby_vax/app/core/widget/app_bottom_navigation_bar.dart';
import '../../../core/imports/import_manger.dart';

class MainMenuView extends GetView<MainMenuController> {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: controller.item[controller.currentIndex.value].title.tr,
            showBackButton: false,
            action: getAppBarAction(),
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

  List<Widget> getAppBarAction() {
    final List<Widget> action = [];
    if(controller.item[controller.currentIndex.value].showEdit){
      action.add(IconButton(
          onPressed: controller.onEditPressed,
          icon: const Icon(Icons.mode_edit_outlined)));
    }
    if (controller.item[controller.currentIndex.value].showSearch) {
      action.add(IconButton(
          onPressed: controller.onSearchPressed,
          icon: const Icon(Icons.search)));
    }
    if (controller.item[controller.currentIndex.value].showAdd) {
      action.add(IconButton(
          onPressed: controller.onAddPressed, icon: const Icon(Icons.add)));
    }
    return action;
  }
}
