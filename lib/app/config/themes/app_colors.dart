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
}
