import 'package:baby_vax/app/core/app_binding.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';

import 'app/config/themes/app_fonts.dart';
import 'app/core/imports/import_manger.dart';
import 'app/core/service/init_app_service.dart';

/// App-wide logger.
///
/// In release builds only warnings and above are emitted, and the pretty
/// printer is dropped: verbose per-operation logs are useful while developing
/// but in release they cost CPU, bloat logcat, and risk leaking user data
/// (names, dates, document paths) to anything reading device logs.
final Logger logger = Logger(
  filter: _ReleaseQuietFilter(),
  printer: kReleaseMode
      ? SimplePrinter(printTime: true)
      : PrettyPrinter(methodCount: 2, errorMethodCount: 8),
);

class _ReleaseQuietFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Before anything can touch AppTheme, so the font never comes from the
  // network.
  configureBundledFonts();
  await initAppService();
  // Null until the user picks a theme in settings: follow the system.
  final bool? isDarkMode =
      AppConstant.getStorage.read(StorageKey.isDarkModeKey);
  final currentLanguage =
      AppConstant.getStorage.read(StorageKey.languageKey) ?? "en";
  runApp(MyApp(
    isDarkMode: isDarkMode,
    currentLanguage: currentLanguage,
  ));
}

class MyApp extends StatelessWidget {
  /// The user's saved choice, or null to follow the system.
  final bool? isDarkMode;
  final String currentLanguage;

  const MyApp({super.key, this.isDarkMode, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      builder: (context, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialBinding: AppBinding(),
          title: "Baby Vax",
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppTheme.themeModeFor(isDarkMode),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.routes,
          locale: Locale(currentLanguage),
          fallbackLocale: Locale(currentLanguage),
          supportedLocales: const [
            Locale("en"),
            Locale("ar"),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          translations: AppTranslations(),
        );
      },
    );

    /*return FutureBuilder<bool>(
        future: _checkLoginState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final bool isLoggedIn = snapshot.data ?? false;
          return ScreenUtilInit(
            designSize: const Size(414, 896),
            builder: (context, _) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                initialBinding: AppBinding(),
                title: "Baby Vax",
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
                initialRoute: AppRoutes.splash,
                getPages: AppPages.routes,
                locale: Locale(currentLanguage),
                fallbackLocale: Locale(currentLanguage),
                supportedLocales: const [
                  Locale("en"),
                  Locale("ar"),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                translations: AppTranslations(),
              );
            },
          );
        });*/
  }

  // Future<bool> _checkLoginState() {
  //   return Future.value(
  //       AppConstant.getStorage.read(AppConstant.isLoginKey) ?? false);
  // }
}
