import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The app's two colour schemes, written out role by role from the tonal
/// palettes in [AppPalette] (see `docs/design/v1.1-polish.md` §1.3).
///
/// Roles the app relies on in both modes: `surfaceContainerLow` is the page
/// (scaffold and app bar), `surface` is a card or sheet, and
/// `surfaceContainer`/`High`/`Highest` are fills on a card.
///
/// v1.0 built these with [ColorScheme.fromSeed], which is why dark mode had
/// to be hand-corrected in twenty-odd widgets: a seeded scheme chooses
/// tonally correct colours, but it cannot know that the brand green is only
/// 3.22:1 on white and so must not be used for text. Writing the roles out
/// means every pair in `docs/design/v1.1-plan.md` §2.1 is a measured value.
class AppColorSchemes {
  const AppColorSchemes._();

  /// Light scheme. `primary` is the primary palette's tone 40, 6.4:1 on
  /// white, so the same colour works as a fill under white text and as text
  /// on a card. The page (`surfaceContainerLow`) is a soft green-tinted
  /// neutral and cards (`surface`) are white, so depth comes from the
  /// surface levels rather than from shadows.
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.p40,
    onPrimary: AppPalette.n100,
    primaryContainer: AppPalette.pd90,
    onPrimaryContainer: AppPalette.p10,
    secondary: AppPalette.s40,
    onSecondary: AppPalette.n100,
    secondaryContainer: AppPalette.s90,
    onSecondaryContainer: AppPalette.s10,
    tertiary: AppPalette.i40,
    onTertiary: AppPalette.n100,
    tertiaryContainer: AppPalette.i90,
    onTertiaryContainer: AppPalette.i10,
    error: AppPalette.e40,
    onError: AppPalette.n100,
    errorContainer: AppPalette.e90,
    onErrorContainer: AppPalette.e10,
    surface: AppPalette.n100,
    onSurface: AppPalette.n10,
    surfaceDim: AppPalette.n90,
    surfaceBright: AppPalette.n100,
    surfaceContainerLowest: AppPalette.n100,
    surfaceContainerLow: AppPalette.n96,
    surfaceContainer: AppPalette.n94,
    surfaceContainerHigh: AppPalette.n92,
    surfaceContainerHighest: AppPalette.n90,
    onSurfaceVariant: AppPalette.nv30,
    outline: AppPalette.nv50,
    outlineVariant: AppPalette.nv90,
    shadow: AppPalette.shadow,
    scrim: AppPalette.shadow,
    inverseSurface: AppPalette.n20,
    onInverseSurface: AppPalette.n95,
    inversePrimary: AppPalette.pd80,
  );

  /// Dark scheme: dark green-tinted surfaces (never pure black), a lighter,
  /// less saturated primary (tone 80 of a chroma-36 palette) that does not
  /// glare, and cards one step lighter than the page so they separate
  /// without borders. Surfaces are opaque.
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.pd80,
    onPrimary: AppPalette.pd20,
    primaryContainer: AppPalette.pd30,
    onPrimaryContainer: AppPalette.pd90,
    secondary: AppPalette.s80,
    onSecondary: AppPalette.s20,
    secondaryContainer: AppPalette.s30,
    onSecondaryContainer: AppPalette.s90,
    tertiary: AppPalette.i80,
    onTertiary: AppPalette.i20,
    tertiaryContainer: AppPalette.i30,
    onTertiaryContainer: AppPalette.i90,
    error: AppPalette.e80,
    onError: AppPalette.e20,
    errorContainer: AppPalette.e30,
    onErrorContainer: AppPalette.e90,
    surface: AppPalette.n12,
    onSurface: AppPalette.n90,
    surfaceDim: AppPalette.n6,
    surfaceBright: AppPalette.n24,
    surfaceContainerLowest: AppPalette.n6,
    surfaceContainerLow: AppPalette.n6,
    surfaceContainer: AppPalette.n17,
    surfaceContainerHigh: AppPalette.n22,
    surfaceContainerHighest: AppPalette.n24,
    onSurfaceVariant: AppPalette.nv80,
    outline: AppPalette.nv60,
    outlineVariant: AppPalette.nv30,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppPalette.n90,
    onInverseSurface: AppPalette.n20,
    inversePrimary: AppPalette.p40,
  );

  /// The scheme for [brightness].
  static ColorScheme of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
