import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The app's two colour schemes, written out role by role.
///
/// v1.0 built these with [ColorScheme.fromSeed], which is why dark mode had
/// to be hand-corrected in twenty-odd widgets: a seeded scheme chooses
/// tonally correct colours, but it cannot know that the brand green is only
/// 3.22:1 on white and so must not be used for text. Writing the roles out
/// means every pair in `docs/design/v1.1-plan.md` §2.1 is a measured value.
class AppColorSchemes {
  const AppColorSchemes._();

  /// Light scheme. `primary` is the brand green darkened to 5.84:1 on white,
  /// so the same colour works as a fill under white text and as text on a
  /// white card.
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.brandDark,
    onPrimary: AppPalette.lightOnPrimary,
    primaryContainer: AppPalette.lightPrimaryContainer,
    onPrimaryContainer: AppPalette.lightOnPrimaryContainer,
    secondary: AppPalette.lightSecondary,
    onSecondary: AppPalette.lightOnPrimary,
    secondaryContainer: AppPalette.lightSecondaryContainer,
    onSecondaryContainer: AppPalette.lightOnSecondaryContainer,
    tertiary: AppPalette.lightTertiary,
    onTertiary: AppPalette.lightOnPrimary,
    tertiaryContainer: AppPalette.lightTertiaryContainer,
    onTertiaryContainer: AppPalette.lightOnTertiaryContainer,
    error: AppPalette.lightError,
    onError: AppPalette.lightOnPrimary,
    errorContainer: AppPalette.lightErrorContainer,
    onErrorContainer: AppPalette.lightOnErrorContainer,
    surface: AppPalette.lightSurface,
    onSurface: AppPalette.lightOnSurface,
    surfaceDim: AppPalette.lightSurfaceContainerHighest,
    surfaceBright: AppPalette.lightSurface,
    surfaceContainerLowest: AppPalette.lightSurface,
    surfaceContainerLow: AppPalette.lightSurfaceContainerLow,
    surfaceContainer: AppPalette.lightSurfaceContainer,
    surfaceContainerHigh: AppPalette.lightSurfaceContainerHigh,
    surfaceContainerHighest: AppPalette.lightSurfaceContainerHighest,
    onSurfaceVariant: AppPalette.lightOnSurfaceVariant,
    outline: AppPalette.lightOutline,
    outlineVariant: AppPalette.lightOutlineVariant,
    shadow: AppPalette.shadow,
    scrim: AppPalette.shadow,
    inverseSurface: AppPalette.darkSurfaceContainer,
    onInverseSurface: AppPalette.darkOnSurface,
    inversePrimary: AppPalette.brandLight,
  );

  /// Dark scheme. Surfaces are **opaque**, unlike v1.0's
  /// `Color(0x454F4F4F)` and `Colors.black.withValues(alpha: 0.2)` cards,
  /// which let the scaffold show through and made every card look muddy.
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brandLight,
    onPrimary: AppPalette.darkOnPrimary,
    primaryContainer: AppPalette.darkPrimaryContainer,
    onPrimaryContainer: AppPalette.darkOnPrimaryContainer,
    secondary: AppPalette.darkSecondary,
    onSecondary: AppPalette.darkOnPrimary,
    secondaryContainer: AppPalette.darkSecondaryContainer,
    onSecondaryContainer: AppPalette.darkOnSecondaryContainer,
    tertiary: AppPalette.darkTertiary,
    onTertiary: AppPalette.darkOnPrimary,
    tertiaryContainer: AppPalette.darkTertiaryContainer,
    onTertiaryContainer: AppPalette.darkOnTertiaryContainer,
    error: AppPalette.darkError,
    onError: AppPalette.darkOnError,
    errorContainer: AppPalette.darkErrorContainer,
    onErrorContainer: AppPalette.darkOnErrorContainer,
    surface: AppPalette.darkSurface,
    onSurface: AppPalette.darkOnSurface,
    surfaceDim: AppPalette.darkSurface,
    surfaceBright: AppPalette.darkSurfaceContainerHighest,
    surfaceContainerLowest: AppPalette.darkSurface,
    surfaceContainerLow: AppPalette.darkSurfaceContainerLow,
    surfaceContainer: AppPalette.darkSurfaceContainer,
    surfaceContainerHigh: AppPalette.darkSurfaceContainerHigh,
    surfaceContainerHighest: AppPalette.darkSurfaceContainerHighest,
    onSurfaceVariant: AppPalette.darkOnSurfaceVariant,
    outline: AppPalette.darkOutline,
    outlineVariant: AppPalette.darkOutlineVariant,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppPalette.lightSurfaceContainerLow,
    onInverseSurface: AppPalette.lightOnSurface,
    inversePrimary: AppPalette.brandDark,
  );

  /// The scheme for [brightness].
  static ColorScheme of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
