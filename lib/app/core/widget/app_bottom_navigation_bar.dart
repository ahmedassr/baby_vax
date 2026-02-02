import 'package:baby_vax/app/config/themes/app_colors.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;
  final double? elevation;
  final Color unselectedItemColor;
  final Color selectedItemColor;
  final bool showSelectedLabels;
  final bool showUnSelectedLabels;

  const AppBottomNavigationBar(
      {super.key,
      required this.currentIndex,
      required this.items,
      required this.onTap,
      this.elevation = 8.0,
      this.selectedItemColor = AppColors.primary,
      this.unselectedItemColor = Colors.grey,
      this.showSelectedLabels = false,
      this.showUnSelectedLabels = false});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: context.isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      elevation: elevation,
      unselectedItemColor: unselectedItemColor,
      selectedItemColor: selectedItemColor,
      showSelectedLabels: showSelectedLabels,
      showUnselectedLabels: showUnSelectedLabels,
      type: BottomNavigationBarType.fixed,
    );
  }
}
