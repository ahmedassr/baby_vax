import 'dart:ui' show Color;

/// The raw colour values of the Baby Vax design system.
///
/// Nothing in the app reads these directly: they are assembled into the two
/// [ColorScheme]s in `app_color_schemes.dart` and into the
/// `AppStatusColors` / `AppElevation` theme extensions. Screens read
/// `Theme.of(context).colorScheme` and those extensions instead, so a colour
/// never has to be chosen twice (once for light, once for dark) inside a
/// widget.
///
/// Every pair that carries text was measured with the WCAG 2.1 relative
/// luminance formula; the ratios are in `docs/design/v1.1-plan.md` §2.1.
/// The short version: text pairs are at least 4.5:1, boundary pairs at least
/// 3:1.
class AppPalette {
  const AppPalette._();

  // ---- brand ------------------------------------------------------------

  /// The Baby Vax green, unchanged from v1.0.
  ///
  /// Illustrative only — logo, splash, adaptive-icon foreground. It is
  /// 3.22:1 on white, so it must never carry text or be used as text.
  static const Color brand = Color(0xFF42A332);

  /// The brand green darkened to the same hue for light-mode interaction
  /// (5.84:1 on white, both as a fill under white text and as text).
  static const Color brandDark = Color(0xFF2E7324);

  /// The brand green lightened for dark-mode interaction (10.87:1 on the
  /// dark surface).
  static const Color brandLight = Color(0xFF8ED97C);

  // ---- light ------------------------------------------------------------

  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFD7EFD0);
  static const Color lightOnPrimaryContainer = Color(0xFF0E2C0A);

  static const Color lightSecondary = Color(0xFF7A4F01);
  static const Color lightSecondaryContainer = Color(0xFFFCEBC8);
  static const Color lightOnSecondaryContainer = Color(0xFF2A1B00);

  static const Color lightTertiary = Color(0xFF1F5F8B);
  static const Color lightTertiaryContainer = Color(0xFFD8ECF8);
  static const Color lightOnTertiaryContainer = Color(0xFF082337);

  static const Color lightError = Color(0xFFB3261E);
  static const Color lightErrorContainer = Color(0xFFF9DEDC);
  static const Color lightOnErrorContainer = Color(0xFF410E0B);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF7F9F7);
  static const Color lightSurfaceContainer = Color(0xFFF1F5F1);
  static const Color lightSurfaceContainerHigh = Color(0xFFE9EFE9);
  static const Color lightSurfaceContainerHighest = Color(0xFFE2E9E3);
  static const Color lightOnSurface = Color(0xFF17201B);
  static const Color lightOnSurfaceVariant = Color(0xFF4C5A50);
  static const Color lightOutline = Color(0xFF79867C);
  static const Color lightOutlineVariant = Color(0xFFCBD6CD);

  // ---- dark -------------------------------------------------------------

  static const Color darkOnPrimary = Color(0xFF0A2A12);
  static const Color darkPrimaryContainer = Color(0xFF2A5A20);
  static const Color darkOnPrimaryContainer = Color(0xFFD7EFD0);

  static const Color darkSecondary = Color(0xFFF5C26B);
  static const Color darkSecondaryContainer = Color(0xFF3D2C06);
  static const Color darkOnSecondaryContainer = Color(0xFFFCEBC8);

  static const Color darkTertiary = Color(0xFF8ECDF2);
  static const Color darkTertiaryContainer = Color(0xFF0E364F);
  static const Color darkOnTertiaryContainer = Color(0xFFD8ECF8);

  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF5F1411);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color darkSurface = Color(0xFF121417);
  static const Color darkSurfaceContainerLow = Color(0xFF171B1D);
  static const Color darkSurfaceContainer = Color(0xFF1B1F22);
  static const Color darkSurfaceContainerHigh = Color(0xFF232829);
  static const Color darkSurfaceContainerHighest = Color(0xFF2D3233);
  static const Color darkOnSurface = Color(0xFFE7EDE8);
  static const Color darkOnSurfaceVariant = Color(0xFFAFBDB3);
  static const Color darkOutline = Color(0xFF8B978D);
  static const Color darkOutlineVariant = Color(0xFF3A4440);

  // ---- dose status ------------------------------------------------------
  //
  // Pending is deliberately neutral slate rather than green: green now means
  // "done", and a schedule where nine of ten rows are green is unreadable.

  static const Color lightPendingFg = Color(0xFF4A5560);
  static const Color lightPendingBg = Color(0xFFEDEFF1);
  static const Color lightCompletedFg = brandDark;
  static const Color lightCompletedBg = lightPrimaryContainer;
  static const Color lightOverdueFg = lightError;
  static const Color lightOverdueBg = lightErrorContainer;
  static const Color lightSkippedFg = lightSecondary;
  static const Color lightSkippedBg = lightSecondaryContainer;

  static const Color darkPendingFg = Color(0xFFC3CCD4);
  static const Color darkPendingBg = Color(0xFF2A3036);
  static const Color darkCompletedFg = brandLight;
  static const Color darkCompletedBg = Color(0xFF24401C);
  static const Color darkOverdueFg = darkError;
  static const Color darkOverdueBg = Color(0xFF4A1512);
  static const Color darkSkippedFg = darkSecondary;
  static const Color darkSkippedBg = Color(0xFF3D2C06);

  // ---- shadows ----------------------------------------------------------

  /// Shadow tint for light-mode elevation. Dark mode draws a border instead,
  /// because a black shadow is invisible on a near-black surface.
  static const Color shadow = Color(0xFF17201B);
}
