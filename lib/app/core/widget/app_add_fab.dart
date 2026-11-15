import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The "add" button floating over a list screen.
///
/// One rule for the whole app (phone review R3): a screen offers one way to
/// add at a time. While its list is empty the empty state's own button is
/// the only one; once the list has items, this button is. So [visible] is
/// the list's "has items" (and not loading), and when it is false nothing
/// is drawn.
class AppAddFab extends StatelessWidget {
  const AppAddFab({
    super.key,
    required this.visible,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final bool visible;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
