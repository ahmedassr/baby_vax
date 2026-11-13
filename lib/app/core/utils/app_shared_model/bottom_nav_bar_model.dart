import 'package:baby_vax/app/core/imports/import_library.dart';

/// One tab of the main menu.
class BottomNavBarModel {
  /// Translation key for the tab label and the app bar title.
  final String title;
  final Widget view;

  /// Outlined icon for an unselected tab.
  final IconData icon;

  /// Filled icon for the selected tab.
  final IconData selectedIcon;

  const BottomNavBarModel({
    required this.title,
    required this.view,
    required this.icon,
    required this.selectedIcon,
  });
}
