import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final double la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

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
    test('light theme uses the darkened brand green as primary', () {
      final ColorScheme scheme = AppTheme.lightTheme.colorScheme;
      expect(scheme.primary, AppColors.primary);
      expect(scheme.primary, AppPalette.brandDark);
      expect(scheme.brightness, Brightness.light);
    });

    test('dark theme is the written-out dark scheme', () {
      final ColorScheme scheme = AppTheme.darkTheme.colorScheme;
      expect(scheme.brightness, Brightness.dark);
      expect(scheme, AppColorSchemes.dark);
      expect(scheme.primary, AppPalette.brandLight);
    });

    test('both themes carry the status and elevation extensions', () {
      for (final ThemeData t in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(t.extension<AppStatusColors>(), isNotNull);
        expect(t.extension<AppElevation>(), isNotNull);
      }
    });

    test('dark surfaces are opaque (v1.0 cards were translucent)', () {
      final ColorScheme s = AppColorSchemes.dark;
      for (final Color c in [
        s.surface,
        s.surfaceContainerLow,
        s.surfaceContainer,
        s.surfaceContainerHigh,
      ]) {
        expect(c.a, 1.0);
      }
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

  // The ratios in docs/design/v1.1-plan.md §2.1, enforced: a palette edit
  // that breaks AA fails here instead of on a parent's phone.
  group('WCAG AA contrast', () {
    for (final ColorScheme s in [AppColorSchemes.light, AppColorSchemes.dark]) {
      final String mode = s.brightness.name;

      test('$mode: text on surfaces is at least 4.5:1', () {
        final Map<String, (Color, Color)> pairs = {
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurface/containerLow': (s.onSurface, s.surfaceContainerLow),
          'onSurface/container': (s.onSurface, s.surfaceContainer),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onSurfaceVariant/containerLow': (
            s.onSurfaceVariant,
            s.surfaceContainerLow
          ),
          'onSurfaceVariant/container': (
            s.onSurfaceVariant,
            s.surfaceContainer
          ),
          'primary/surface': (s.primary, s.surface),
          'primary/containerLow': (s.primary, s.surfaceContainerLow),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onPrimaryContainer/primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer
          ),
          'error/surface': (s.error, s.surface),
          'onErrorContainer/errorContainer': (
            s.onErrorContainer,
            s.errorContainer
          ),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer
          ),
          'onTertiaryContainer/tertiaryContainer': (
            s.onTertiaryContainer,
            s.tertiaryContainer
          ),
          'onInverseSurface/inverseSurface': (
            s.onInverseSurface,
            s.inverseSurface
          ),
        };
        pairs.forEach((name, p) {
          expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5),
              reason: '$mode $name');
        });
      });

      test('$mode: outline is at least 3:1 against the background', () {
        expect(contrast(s.outline, s.surfaceContainerLow),
            greaterThanOrEqualTo(3.0));
      });
    }

    test('every status chip pair is at least 4.5:1', () {
      for (final AppStatusColors c in [
        AppStatusColors.light,
        AppStatusColors.dark
      ]) {
        for (final DoseDisplayStatus st in DoseDisplayStatus.values) {
          final pair = c.forStatus(st);
          expect(contrast(pair.foreground, pair.background),
              greaterThanOrEqualTo(4.5),
              reason: '$st');
        }
      }
    });

    test('the brand green is not usable as text, which is why it is not', () {
      expect(contrast(AppColors.brand, Colors.white), lessThan(4.5));
      expect(
          contrast(AppColors.primary, Colors.white), greaterThanOrEqualTo(4.5));
    });
  });
}
