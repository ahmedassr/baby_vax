import 'package:flutter/material.dart';

/// The app's one type scale, mapped onto Material's [TextTheme] roles.
///
/// v1.0 had 25 styles in five overlapping families (`headLine*`, `title*`,
/// `body*`, `text*`, `caption*`, `bold*`) at sizes 12–34, and screens then
/// bypassed them anyway with `copyWith(fontSize: 32)`. Worse, the app's own
/// styles and `Theme.of(context).textTheme` disagreed, so a Material widget
/// and an `AppText` next to it rendered at different sizes.
///
/// Twelve roles, each with an explicit `height`, is the whole scale.
/// Sizes are logical pixels (no `ScreenUtil`), so the OS text-scale setting
/// is the only thing that changes them — which is what makes the 1.3-scale
/// requirement testable.
///
/// Why every role pins `height`: the bundled Cairo has an intrinsic line
/// height close to 2.0, so without it a 15px body line occupies ~30px and
/// the vertical rhythm collapses.
class AppTypography {
  const AppTypography._();

  /// Line heights, as multiples of the font size.
  static const double tightHeight = 1.2;
  static const double headingHeight = 1.25;
  static const double titleHeight = 1.4;
  static const double bodyHeight = 1.5;

  /// Builds the scale in [fontFamily], with [onSurface] as the ink and
  /// [onSurfaceVariant] for the secondary roles.
  ///
  /// Only `bodySmall` and `labelSmall` take the variant ink: everything else
  /// is primary text, and a widget that wants it dimmer asks for
  /// `onSurfaceVariant` explicitly rather than inheriting a surprise.
  static TextTheme textTheme({
    required String fontFamily,
    required Color onSurface,
    required Color onSurfaceVariant,
  }) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      Color? color,
    }) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? onSurface,
        );

    return TextTheme(
      // Onboarding and the splash wordmark.
      displayLarge: style(40, FontWeight.w800, headingHeight),
      displayMedium: style(36, FontWeight.w800, headingHeight),
      displaySmall: style(32, FontWeight.w800, headingHeight),
      // Screen hero titles.
      headlineLarge: style(30, FontWeight.w800, headingHeight),
      headlineMedium: style(26, FontWeight.w800, headingHeight),
      // Section titles and the app bar.
      headlineSmall: style(22, FontWeight.w700, 1.3),
      // Card titles, the dose name.
      titleLarge: style(19, FontWeight.w700, 1.35),
      // List row titles.
      titleMedium: style(17, FontWeight.w700, titleHeight),
      // Overlines and field labels.
      titleSmall: style(15, FontWeight.w700, titleHeight),
      // Reading text.
      bodyLarge: style(16, FontWeight.w400, bodyHeight),
      // The default body size.
      bodyMedium: style(15, FontWeight.w400, bodyHeight),
      // Captions and helper text.
      bodySmall: style(13, FontWeight.w400, 1.45, color: onSurfaceVariant),
      // Button labels.
      labelLarge: style(15, FontWeight.w600, tightHeight),
      // Chips.
      labelMedium: style(13, FontWeight.w600, tightHeight),
      // Badges.
      labelSmall:
          style(11, FontWeight.w600, tightHeight, color: onSurfaceVariant),
    );
  }
}
