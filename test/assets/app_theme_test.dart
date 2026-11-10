import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('theme mode', () {
    test('follows the system until the user picks one', () {
      expect(AppTheme.themeModeFor(null), ThemeMode.system);
    });

    test('uses the user\'s choice once made', () {
      expect(AppTheme.themeModeFor(true), ThemeMode.dark);
      expect(AppTheme.themeModeFor(false), ThemeMode.light);
    });
  });

  group('colour scheme', () {
    test('light theme uses the app green as primary', () {
      final ColorScheme scheme = AppTheme.lightTheme.colorScheme;
      expect(scheme.primary, AppColors.primary);
      expect(scheme.brightness, Brightness.light);
    });

    test('dark theme is a dark scheme from the same seed', () {
      final ColorScheme scheme = AppTheme.darkTheme.colorScheme;
      expect(scheme.brightness, Brightness.dark);
      expect(
          scheme,
          ColorScheme.fromSeed(
              seedColor: AppColors.primary, brightness: Brightness.dark));
    });

    testWidgets('the date picker is drawn in the app colours', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 1, 15),
              firstDate: DateTime(2000),
              lastDate: DateTime(2027),
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The selected day is painted with the theme's primary colour.
      final BuildContext dialog = tester.element(find.byType(DatePickerDialog));
      expect(Theme.of(dialog).colorScheme.primary, AppColors.primary);
      Color? fill(Decoration? d) => switch (d) {
            BoxDecoration(:final color) => color,
            ShapeDecoration(:final color) => color,
            _ => null,
          };
      final Iterable<Color?> fills = tester
          .widgetList<Ink>(find.descendant(
              of: find.byType(DatePickerDialog), matching: find.byType(Ink)))
          .map((ink) => fill(ink.decoration));
      expect(fills, contains(AppColors.primary));
    });
  });
}
