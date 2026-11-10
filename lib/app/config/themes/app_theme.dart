import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final String fontFamily = GoogleFonts.cairo().fontFamily ?? "Arial";

  // Text Theme
  static TextTheme getTextTheme(Color textColor) => TextTheme(
        displayLarge: AppTextStyles.headLineLarge.copyWith(color: textColor),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textColor),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textColor),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textColor),
        labelLarge: AppTextStyles.textLarge.copyWith(color: textColor),
      );

  // Elevated Button Style
  static ButtonStyle getElevatedButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondPrimary,
        textStyle: AppTextStyles.textLarge,
      );

  /// The app's green as a full Material colour scheme. Without one, dialogs
  /// and pickers (the sign-up date picker) fell back to Material's default
  /// purple.
  static ColorScheme colorScheme(Brightness brightness) => ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: brightness == Brightness.light ? AppColors.primary : null,
      );

  /// Which theme to use for the stored choice. Nothing stored means the user
  /// hasn't picked one, so follow the system.
  static ThemeMode themeModeFor(bool? storedIsDark) => switch (storedIsDark) {
        true => ThemeMode.dark,
        false => ThemeMode.light,
        null => ThemeMode.system,
      };

  // Light Mode
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme(Brightness.light),
    fontFamily: fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: getTextTheme(AppColors.textBlack),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: getElevatedButtonStyle()),
  );

  // Dark Mode
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme(Brightness.dark),
    fontFamily: fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: getTextTheme(AppColors.textWhite),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: getElevatedButtonStyle()),
  );
}
