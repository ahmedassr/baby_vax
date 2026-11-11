import '../../core/imports/import_manger.dart';

/// v1.0's text styles, re-pointed at the v1.1 type scale.
///
/// New code uses `Theme.of(context).textTheme` roles (see [AppTypography]).
/// These names stay only until every screen is migrated, and now resolve to
/// the nearest role instead of their own sizes, so the old screens already
/// render on the scale. They carry no colour: the ink comes from the theme.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get base => TextStyle(
        height: AppTypography.bodyHeight,
        fontFamily: AppTheme.fontFamily,
      );

  static TextStyle style(double size, FontWeight weight, double height) =>
      base.copyWith(fontSize: size, fontWeight: weight, height: height);

  // headline -> headlineMedium / headlineSmall
  static final headLineLarge = style(30, FontWeight.w800, 1.25);
  static final headLineMedium = style(26, FontWeight.w800, 1.25);
  static final headLineSmall = style(22, FontWeight.w700, 1.3);
  static final headLineExtraSmall = style(19, FontWeight.w700, 1.35);

  // titles -> titleLarge / titleMedium / titleSmall
  static final titleLarge = style(19, FontWeight.w700, 1.35);
  static final titleMedium = style(17, FontWeight.w700, 1.4);
  static final titleSmall = style(15, FontWeight.w700, 1.4);

  // body -> bodyLarge / bodyMedium / bodySmall
  static final bodyLarge = style(16, FontWeight.w400, 1.5);
  static final bodyMedium = style(15, FontWeight.w400, 1.5);
  static final bodySmall = style(13, FontWeight.w400, 1.45);

  // text -> body roles
  static final textLarge = style(17, FontWeight.w400, 1.5);
  static final textMedium = style(16, FontWeight.w400, 1.5);
  static final textSmall = style(15, FontWeight.w400, 1.5);
  static final textExtraSmall = style(13, FontWeight.w400, 1.45);

  // caption -> bodySmall / labelSmall
  static final captionLarge = style(13, FontWeight.w400, 1.45);
  static final captionMedium = style(13, FontWeight.w400, 1.45);
  static final captionSmall = style(11, FontWeight.w600, 1.2);

  // bold -> titleMedium / titleSmall
  static final boldLarge = style(17, FontWeight.w700, 1.4);
  static final boldMedium = style(15, FontWeight.w700, 1.4);
  static final boldSmall = style(13, FontWeight.w700, 1.4);
}
