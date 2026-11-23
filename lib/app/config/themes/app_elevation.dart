import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The app's three elevation levels, as a [ThemeExtension].
///
/// Depth comes from surface levels first (polish §1.4): white cards on a
/// tinted page in light mode, cards one tone lighter than the page in dark
/// mode. Shadows only soften that in light mode, and are kept faint; dark
/// mode never draws a shadow or a border, and lifts a raised card by one
/// more surface step ([AppElevationLevel.fill]) instead.
@immutable
class AppElevation extends ThemeExtension<AppElevation> {
  const AppElevation({
    required this.level0,
    required this.level1,
    required this.level2,
  });

  /// Light: faint shadows, no borders.
  static const AppElevation light = AppElevation(
    level0: AppElevationLevel(shadows: <BoxShadow>[]),
    level1: AppElevationLevel(shadows: <BoxShadow>[
      BoxShadow(
        color: Color(0x0A181D18), // ~4% of the surface ink
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ]),
    level2: AppElevationLevel(shadows: <BoxShadow>[
      BoxShadow(
        color: Color(0x0F181D18), // ~6%
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ]),
  );

  /// Dark: no shadows, no borders; a raised card is one surface step up.
  static const AppElevation dark = AppElevation(
    level0: AppElevationLevel(shadows: <BoxShadow>[]),
    level1: AppElevationLevel(shadows: <BoxShadow>[]),
    level2: AppElevationLevel(
      shadows: <BoxShadow>[],
      fill: AppPalette.n17,
    ),
  );

  /// Flat: no separation from the surface behind it.
  final AppElevationLevel level0;

  /// Resting cards and list rows.
  final AppElevationLevel level1;

  /// Hero cards, sheets and anything that floats.
  final AppElevationLevel level2;

  /// The extension from [context], falling back to the level set for the
  /// current brightness if the theme does not carry one.
  static AppElevation of(BuildContext context) =>
      Theme.of(context).extension<AppElevation>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppElevation copyWith({
    AppElevationLevel? level0,
    AppElevationLevel? level1,
    AppElevationLevel? level2,
  }) {
    return AppElevation(
      level0: level0 ?? this.level0,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
    );
  }

  @override
  AppElevation lerp(ThemeExtension<AppElevation>? other, double t) {
    // Elevation is a discrete token, not a continuum: cross-fading a shadow
    // into a border produces neither. Snap at the halfway point instead.
    if (other is! AppElevation) return this;
    return t < 0.5 ? this : other;
  }
}

/// One elevation level: the shadows to paint, an optional border and an
/// optional fill that replaces the card colour.
@immutable
class AppElevationLevel {
  const AppElevationLevel({required this.shadows, this.border, this.fill});

  final List<BoxShadow> shadows;

  /// Card colour at this level, or null for the scheme's `surface`.
  final Color? fill;

  /// Hairline border colour, or null when this level uses shadows only.
  final Color? border;

  /// A 1px border side for this level, or [BorderSide.none].
  BorderSide get borderSide =>
      border == null ? BorderSide.none : BorderSide(color: border!, width: 1);
}
