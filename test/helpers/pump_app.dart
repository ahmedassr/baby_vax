import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The small-phone viewport the redesign must fit: 360x640 logical pixels.
const Size smallPhone = Size(360, 640);

/// Every combination a main screen is checked in.
class Variant {
  const Variant(this.locale, this.brightness, this.textScale);

  final String locale;
  final Brightness brightness;
  final double textScale;

  bool get rtl => locale == 'ar';

  @override
  String toString() =>
      '$locale ${brightness.name} x$textScale${rtl ? ' RTL' : ''}';
}

/// English light, Arabic RTL dark, and both at the 1.3 text scale.
const List<Variant> mainVariants = <Variant>[
  Variant('en', Brightness.light, 1.0),
  Variant('ar', Brightness.dark, 1.0),
  Variant('en', Brightness.dark, 1.3),
  Variant('ar', Brightness.light, 1.3),
];

/// Pumps [child] inside a GetMaterialApp with the app's themes and
/// translations, at [size] and [variant].
///
/// Overflow is a test failure on its own: Flutter reports a RenderFlex
/// overflow as an exception, which `tester.takeException()` returns and
/// [expectNoOverflow] checks.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Variant variant = const Variant('en', Brightness.light, 1.0),
  Size size = smallPhone,
  bool settle = true,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = variant.textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  Get.testMode = true;
  await tester.pumpWidget(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: variant.brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light,
    translations: AppTranslations(),
    locale: Locale(variant.locale),
    fallbackLocale: const Locale('en'),
    supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ));
  if (settle) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Fails if layout threw (a RenderFlex overflow, most often).
void expectNoOverflow(WidgetTester tester) {
  final Object? e = tester.takeException();
  expect(e, isNull, reason: 'layout error: $e');
}

/// Every tappable widget with a semantic action is at least 48x48.
Future<void> expectTapTargets(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
}

/// Every tappable widget has a label.
Future<void> expectLabelledTargets(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}
