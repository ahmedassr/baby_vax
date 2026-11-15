import '../../../core/imports/import_manger.dart';
import '../../reminders/controller/reminders_controller.dart';

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
        // On the schedule tab: add a reminder or appointment of the
        // parent's own (v1.0 had a FAB here whose handler was a TODO). Not
        // an "add" for the schedule's own list, whose empty states offer
        // Retry / Show all, so it never duplicates one.
        floatingActionButton: AppAddFab(
          key: const Key('schedule_add_reminder'),
          visible: index == 1,
          label: "Reminders_add".tr,
          icon: Icons.add_alarm_rounded,
          onPressed: () => Get.toNamed(AppRoutes.reminders,
              arguments: RemindersController.openAddArgument),
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
