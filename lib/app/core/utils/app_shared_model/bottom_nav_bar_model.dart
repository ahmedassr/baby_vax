import 'package:baby_vax/app/core/imports/import_library.dart';

class BottomNavBarModel {
  final String title;
  final Widget view;
  final IconData icon;
  final bool showSearch;
  final bool showAdd;
  final bool showEdit;

  BottomNavBarModel(
      {required this.title,
      required this.view,
      required this.icon,
      this.showAdd = false,
      this.showSearch = false,
      this.showEdit = false});
}
