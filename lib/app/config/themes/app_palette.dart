import 'dart:ui' show Color;

/// The raw colour values of the Baby Vax design system.
///
/// Nothing in the app reads these directly: they are assembled into the two
/// [ColorScheme]s in `app_color_schemes.dart` and into the `AppStatusColors`,
/// `AppChartColors` and `AppElevation` theme extensions. Screens read
/// `Theme.of(context).colorScheme` and those extensions instead, so a colour
/// never has to be chosen twice (once for light, once for dark) inside a
/// widget.
///
/// Every value is a tone of a Material 3 tonal palette (HCT colour space)
/// built around the brand green's hue, 141.9; `tool/palette/tones.dart`
/// regenerates them and `docs/design/v1.1-polish.md` §1 explains each
/// choice. Contrast of every text pair is checked by
/// `test/theme/contrast_test.dart` (at least 4.5:1, both modes).
class AppPalette {
  const AppPalette._();

  // ---- brand ------------------------------------------------------------

  /// The Baby Vax green, unchanged from v1.0 (HCT 141.9 / 67 / 60).
  ///
  /// Illustrative only: logo, splash, adaptive-icon foreground. It is
  /// 3.22:1 on white, so it must never carry text or be used as text.
  static const Color brand = Color(0xFF42A332);

  /// Light-mode primary: primary palette tone 40.
  static const Color brandDark = p40;

  /// Dark-mode primary: the softer dark palette's tone 80.
  static const Color brandLight = pd80;

  // ---- tonal palettes -----------------------------------------------------

  // Primary: hue 141.9, chroma 48.
  static const Color p10 = Color(0xFF012200);
  static const Color p30 = Color(0xFF17520E);
  static const Color p40 = Color(0xFF306B25);

  // Primary for dark mode and containers: hue 141.9, chroma 36. Lighter and
  // less saturated, so a filled button does not glare on a dark page.
  static const Color pd20 = Color(0xFF12380B);
  static const Color pd30 = Color(0xFF295020);
  static const Color pd80 = Color(0xFFA5D395);
  static const Color pd90 = Color(0xFFC1EFAF);

  // Secondary: hue 141.9, chroma 16 (a muted sage).
  static const Color s10 = Color(0xFF121F0E);
  static const Color s20 = Color(0xFF263422);
  static const Color s30 = Color(0xFF3C4B37);
  static const Color s40 = Color(0xFF54634D);
  static const Color s80 = Color(0xFFBBCBB1);
  static const Color s90 = Color(0xFFD7E8CD);

  // Neutral: hue 155, chroma 6. Green-tinted, never flat grey; a little
  // cooler than the brand hue, which at low chroma reads as cream.
  static const Color n6 = Color(0xFF101510);
  static const Color n10 = Color(0xFF181D18);
  static const Color n12 = Color(0xFF1C211C);
  static const Color n17 = Color(0xFF262B26);
  static const Color n20 = Color(0xFF2D322D);
  static const Color n22 = Color(0xFF313631);
  static const Color n24 = Color(0xFF353A35);
  static const Color n90 = Color(0xFFDFE4DC);
  static const Color n92 = Color(0xFFE5EAE2);
  static const Color n94 = Color(0xFFEBEFE7);
  static const Color n95 = Color(0xFFEEF2EA);
  static const Color n96 = Color(0xFFF0F5ED);
  static const Color n100 = Color(0xFFFFFFFF);

  // Neutral variant: hue 155, chroma 10.
  static const Color nv30 = Color(0xFF3F4940);
  static const Color nv50 = Color(0xFF6F7A6F);
  static const Color nv60 = Color(0xFF899488);
  static const Color nv80 = Color(0xFFBECABD);
  static const Color nv90 = Color(0xFFDAE6D9);
  static const Color nv92 = Color(0xFFE0EBDE);

  // Error: hue 30, chroma 70.
  static const Color e10 = Color(0xFF3E0400);
  static const Color e20 = Color(0xFF650B00);
  static const Color e30 = Color(0xFF8C1703);
  static const Color e40 = Color(0xFFAE3019);
  static const Color e80 = Color(0xFFFFB4A5);
  static const Color e90 = Color(0xFFFFDAD3);

  // Warning (amber, harmonised toward the green): hue 80, chroma 50.
  static const Color w30 = Color(0xFF5F4100);
  static const Color w40 = Color(0xFF7D5700);
  static const Color w80 = Color(0xFFFBBB42);
  static const Color w90 = Color(0xFFFFDEAB);

  // Info (v1.1's blue, harmonised): hue 233.4, chroma 42.
  static const Color i10 = Color(0xFF001E2C);
  static const Color i20 = Color(0xFF003549);
  static const Color i30 = Color(0xFF004D68);
  static const Color i40 = Color(0xFF006689);
  static const Color i80 = Color(0xFF7ED0FC);
  static const Color i90 = Color(0xFFC2E8FF);

  // ---- splash --------------------------------------------------------------

  /// Splash background, light: the brand green at tone 40. The system splash
  /// and the Flutter splash both use it, so the hand-over is invisible.
  static const Color splashLight = p40;

  /// Splash background, dark: a deep green (tone 20), not a bright fill in
  /// a dark room.
  static const Color splashDark = pd20;

  /// The mark drawn on the splash green: a light shield with the green leaf
  /// inside it (the standard mark's green shield would vanish on green).
  static const Color markShieldOnLight = n100;
  static const Color markShieldOnDark = n95;
  static const Color markLeaf = brand;
  static const Color markLeafHighlight = pd90;
  static const Color markVein = p30;

  /// The mark's own colours (assets/branding/logo.svg).
  static const Color markShield = Color(0xFF2E7324);
  static const Color markLeafLight = Color(0xFF8ED97C);

  // ---- names other code reads (the PDF card, tests) ------------------------

  /// Light page colour, and the native splash's light background.
  static const Color lightPage = n96;

  /// Dark page colour, and the native splash's dark background.
  static const Color darkPage = n6;

  static const Color lightOnSurface = n10;
  static const Color lightOnSurfaceVariant = nv30;
  static const Color lightOutlineVariant = nv90;
  static const Color lightPrimaryContainer = pd90;

  // ---- shadows ----------------------------------------------------------

  /// Shadow tint for light-mode elevation: the surface ink, not black.
  static const Color shadow = n10;
}
