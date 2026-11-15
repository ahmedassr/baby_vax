// Phone review R6: Flutter's own licence page, from About, in the app's
// theme and font in light and dark.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/widget/about_baby_vax.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  setUp(() {
    LicenseRegistry.reset();
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(<String>[
        'Cairo font'
      ], 'Copyright 2009 The Cairo Project Authors\n\nThis Font Software is licensed under the SIL Open Font License, Version 1.1.');
    });
  });
  tearDown(Get.reset);

  for (final Variant v in const <Variant>[
    Variant('en', Brightness.light, 1.0),
    Variant('en', Brightness.dark, 1.0),
    Variant('ar', Brightness.dark, 1.3),
  ]) {
    testWidgets('About -> licences, in the app theme and font ($v)',
        (tester) async {
      await pumpApp(
          tester,
          const Scaffold(
              body: Center(
                  child: TextButton(
                      onPressed: AboutBabyVax.show, child: Text('about')))),
          variant: v);
      await tester.tap(find.text('about'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('about_dialog')), findsOneWidget);
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('about_licenses')));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
      final ThemeData app = v.brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
      final ThemeData page = Theme.of(tester.element(find.byType(LicensePage)));
      expect(page.brightness, v.brightness);
      expect(page.colorScheme, app.colorScheme);
      // No white slab: the page's sheet is the app's background.
      expect(page.cardColor, app.scaffoldBackgroundColor);
      // The app's font everywhere on the page.
      for (final Element e in find
          .descendant(
              of: find.byType(LicensePage), matching: find.byType(RichText))
          .evaluate()) {
        final TextStyle? style = (e.widget as RichText).text.style;
        // Icons are drawn with their own icon font.
        if (style?.fontFamily != null && style!.fontFamily != 'MaterialIcons') {
          expect(style.fontFamily, AppTheme.fontFamily,
              reason: (e.widget as RichText).text.toPlainText());
        }
      }
      expectNoOverflow(tester);

      // A package's licence text, readable and in the app font.
      await tester.tap(find.text('Cairo font'));
      await tester.pumpAndSettle();
      final Finder licence =
          find.textContaining('SIL Open Font License', findRichText: true);
      expect(licence, findsOneWidget);
      final TextStyle body = DefaultTextStyle.of(tester.element(licence)).style;
      expect(body.fontFamily, AppTheme.fontFamily);
      expect(body.fontSize, app.textTheme.bodyMedium!.fontSize);
      expect(body.color, app.colorScheme.onSurface);
      expectNoOverflow(tester);
    });
  }

  test('the licence theme changes only what the page needs', () {
    for (final ThemeData t in <ThemeData>[
      AppTheme.lightTheme,
      AppTheme.darkTheme
    ]) {
      final ThemeData l = AppTheme.licenseTheme(t);
      expect(l.cardColor, t.scaffoldBackgroundColor);
      expect(l.appBarTheme.titleTextStyle, t.textTheme.titleLarge);
      expect(l.textTheme.bodySmall, t.textTheme.bodyMedium);
      expect(l.colorScheme, t.colorScheme);
      expect(l.appBarTheme.backgroundColor, t.appBarTheme.backgroundColor);
    }
  });
}
