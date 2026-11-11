import '../../core/imports/import_library.dart';
import 'app_palette.dart';

/// Brand colours for the few places that are illustration, not interface:
/// the logo, the splash and the onboarding art.
///
/// Interface colour comes from `Theme.of(context).colorScheme` and the
/// `AppStatusColors` / `AppElevation` theme extensions, which already know
/// whether the app is light or dark. v1.0 kept a parallel palette here
/// (`backgroundDark`, `cardDark`, `buttonLight`, `textGrey`, …) that widgets
/// picked from with `isDark ? … : …`; those are gone, and
/// `test/assets/design_system_test.dart` fails if a screen reintroduces a
/// raw colour.
class AppColors {
  const AppColors._();

  /// The Baby Vax green. Illustration only: 3.22:1 on white, never text.
  static const Color brand = AppPalette.brand;

  /// The light theme's `primary`: the brand green darkened to 5.84:1 on
  /// white. Equal to `AppTheme.lightTheme.colorScheme.primary`.
  static const Color primary = AppPalette.brandDark;

  /// Pure white, for text on the brand fill in illustrations.
  static const Color white = Color(0xFFFFFFFF);

  /// Fully transparent.
  static const Color transparent = Colors.transparent;

  // ---- v1.0 names, removed once every screen is migrated ----------------
  // Kept only so each screen can move onto the theme in its own commit
  // without a flag day. They point at palette values now, so the screens
  // that still use them already get the measured colours.

  static const Color secondPrimary = AppPalette.lightPrimaryContainer;
  static const Color black = Color(0xFF000000);
  static const Color textHint = AppPalette.lightOnSurfaceVariant;
  static const Color textWhite = AppPalette.darkOnSurface;
  static const Color textBlack = AppPalette.lightOnSurface;
  static const Color textGrey = AppPalette.lightOnSurfaceVariant;
  static const Color backgroundLight = AppPalette.lightSurfaceContainerLow;
  static const Color backgroundDark = AppPalette.darkSurface;
  static const Color buttonDark = AppPalette.darkPrimaryContainer;
  static const Color buttonLight = AppPalette.lightPrimaryContainer;
  static const Color cardDark = AppPalette.darkSurfaceContainer;
  static const Color greyMedium = AppPalette.darkOnSurfaceVariant;
  static const Color greyDark = AppPalette.lightOnSurfaceVariant;
  static const Color greyLight = AppPalette.lightSurfaceContainerHigh;
  static const Color accent = AppPalette.darkSecondary;
  static const Color error = AppPalette.lightError;
  static const Color warning = accent;
  static const Color success = AppPalette.brandDark;
  static const Color info = AppPalette.lightTertiary;
}
