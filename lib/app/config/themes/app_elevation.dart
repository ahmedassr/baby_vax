import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The app's three elevation levels, as a [ThemeExtension].
///
/// v1.0 hand-rolled a shadow in every card, always wrapped in
/// `if (!context.isDarkMode)` — eight widgets, six different
/// blur/offset/alpha combinations. The `if` was right (a black shadow is
/// invisible on a near-black surface) but it meant dark mode had no
/// separation between a card and the scaffold at all.
///
/// Here each level knows both halves: a shadow in light mode, a hairline
/// border in dark mode. [AppElevationLevel.border] is null in light mode and
/// the widget simply does not draw one.
@immutable
class AppElevation extends ThemeExtension<AppElevation> {
  const AppElevation({
    required this.level0,
    required this.level1,
    required this.level2,
  });

  /// Light: real shadows, no borders.
  static const AppElevation light = AppElevation(
    level0: AppElevationLevel(shadows: <BoxShadow>[]),
    level1: AppElevationLevel(shadows: <BoxShadow>[
      BoxShadow(
        color: Color(0x0F17201B), // ~6% of the surface ink
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0A17201B), // ~4%
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ]),
    level2: AppElevationLevel(shadows: <BoxShadow>[
      BoxShadow(
        color: Color(0x1417201B), // ~8%
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ]),
  );

  /// Dark: hairline borders, no shadows.
  static const AppElevation dark = AppElevation(
    level0: AppElevationLevel(shadows: <BoxShadow>[]),
    level1: AppElevationLevel(
      shadows: <BoxShadow>[],
      border: AppPalette.darkOutlineVariant,
    ),
    level2: AppElevationLevel(
      shadows: <BoxShadow>[],
      border: AppPalette.darkOutline,
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

/// One elevation level: the shadows to paint, and in dark mode the border
/// colour to draw instead.
@immutable
class AppElevationLevel {
  const AppElevationLevel({required this.shadows, this.border});

  final List<BoxShadow> shadows;

  /// Hairline border colour, or null when this level uses shadows only.
  final Color? border;

  /// A 1px border side for this level, or [BorderSide.none].
  BorderSide get borderSide =>
      border == null ? BorderSide.none : BorderSide(color: border!, width: 1);
}
