import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A small rounded square with an icon in it, used as a list row's leading
/// visual and in section headers.
///
/// Replaces v1.0's `AppLeadingIcon`, which was always `AppColors.primary` on
/// a 10% tint of itself — 2.3:1 in dark mode.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
    this.foreground,
  });

  final IconData icon;

  /// Edge length of the square.
  final double size;

  /// Defaults to `primaryContainer`.
  final Color? background;

  /// Defaults to `onPrimaryContainer`.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Decorative: whatever sits next to it carries the meaning.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? scheme.primaryContainer,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size * 0.55,
          color: foreground ?? scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
