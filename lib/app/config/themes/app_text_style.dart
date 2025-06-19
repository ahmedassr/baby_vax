import '../../core/imports/import_manger.dart';

class AppTextStyles {
  static TextStyle get base => TextStyle(
        height: 1.3,
        fontFamily: AppTheme.fontFamily,
      );

  static TextStyle style(double size, FontWeight weight) =>
      base.copyWith(fontSize: size, fontWeight: weight);

  //headline
  static final headLineLarge = style(34, FontWeight.w800);
  static final headLineMedium = style(32, FontWeight.w800);
  static final headLineSmall = style(24, FontWeight.w700);

  //titles
  static final titleLarge = style(22, FontWeight.w800);
  static final titleMedium = style(20, FontWeight.w800);
  static final titleSmall = style(18, FontWeight.w800);

  // body
  static final bodyLarge = style(17, FontWeight.w500);
  static final bodyMedium = style(16, FontWeight.normal);
  static final bodySmall = style(15, FontWeight.normal);

  //text
  static final textLarge = style(24, FontWeight.normal);
  static final textMedium = style(20, FontWeight.normal);
  static final textSmall = style(18, FontWeight.normal);
  static final textExtraSmall = style(16, FontWeight.normal);

  //Caption
  static final captionLarge = style(14, FontWeight.normal);
  static final captionMedium = style(13, FontWeight.normal);
  static final captionSmall = style(12, FontWeight.normal);
}
