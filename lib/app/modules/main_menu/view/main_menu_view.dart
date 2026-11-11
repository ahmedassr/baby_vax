import '../../../core/imports/import_manger.dart';

/// The signed-in shell: a title bar and four tabs with their labels always
/// visible (v1.0 hid them, leaving four bare icons).
class MainMenuView extends GetView<MainMenuController> {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final int index = controller.currentIndex.value;
      return Scaffold(
        appBar: CustomAppBar(
          title: controller.item[index].title.tr,
          showBackButton: false,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.changeValue,
          destinations: <NavigationDestination>[
            for (final BottomNavBarModel item in controller.item)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.title.tr,
              ),
          ],
        ),
        // IndexedStack keeps each tab's scroll position when switching.
        body: IndexedStack(
          index: index,
          children: <Widget>[
            for (final BottomNavBarModel item in controller.item) item.view,
          ],
        ),
      );
    });
  }
}
