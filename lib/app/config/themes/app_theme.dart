import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final String fontFamily = GoogleFonts.cairo().fontFamily ?? "Arial";

  static TextTheme getTextTheme(Color textColor) => TextTheme(
        displayLarge: AppTextStyles.headLineLarge.copyWith(color: textColor),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textColor),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textColor),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textColor),
        labelLarge: AppTextStyles.textLarge.copyWith(color: textColor),
      );

  static ButtonStyle getElevatedButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondPrimary,
        textStyle: AppTextStyles.textLarge,
      );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: getTextTheme(AppColors.textBlack),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: getElevatedButtonStyle()),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: getTextTheme(AppColors.textWhite),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: getElevatedButtonStyle()),
  );
}
