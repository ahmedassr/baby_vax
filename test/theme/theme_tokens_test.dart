// The design-system tokens behind the v1.1 polish (docs/design/v1.1-polish.md
// §1): one green family, dark mode without pure black, depth from surface
// levels, and every extension present in both themes.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

/// True when [c] leans green: its green channel is the largest.
bool greenTinted(Color c) => c.g >= c.r && c.g >= c.b;

void main() {
  final ThemeData light = AppTheme.lightTheme;
  final ThemeData dark = AppTheme.darkTheme;

  test('the brand green itself is unchanged', () {
    expect(AppColors.brand, const Color(0xFF42A332));
  });

  test('light primary is the brand hue at tone 40, close to v1.1', () {
    expect(light.colorScheme.primary, AppPalette.p40);
    expect(greenTinted(light.colorScheme.primary), isTrue);
  });

  test('dark primary is lighter and less saturated than light', () {
    final HSLColor l = HSLColor.fromColor(light.colorScheme.primary);
    final HSLColor d = HSLColor.fromColor(dark.colorScheme.primary);
    expect(d.lightness, greaterThan(l.lightness));
    // The old dark primary #8ED97C was saturation 0.55; the new one is calmer.
    expect(d.saturation,
        lessThan(HSLColor.fromColor(const Color(0xFF8ED97C)).saturation));
  });

  test('page and cards are green-tinted, never flat grey or pure black', () {
    for (final ThemeData t in <ThemeData>[light, dark]) {
      final ColorScheme s = t.colorScheme;
      for (final Color c in <Color>[
        t.scaffoldBackgroundColor,
        s.surfaceContainer,
        s.surfaceContainerHigh,
        s.surfaceContainerHighest,
      ]) {
        expect(greenTinted(c), isTrue, reason: '$c');
        expect(c.r == c.g && c.g == c.b, isFalse, reason: '$c is grey');
      }
    }
    expect(dark.scaffoldBackgroundColor, isNot(const Color(0xFF000000)));
    expect(dark.colorScheme.surface, isNot(const Color(0xFF000000)));
  });

  test('the page is the same colour as the native splash', () {
    expect(light.scaffoldBackgroundColor, AppPalette.lightPage);
    expect(dark.scaffoldBackgroundColor, AppPalette.darkPage);
  });

  test('cards stand out from the page by surface level', () {
    // Light: white cards on the tinted page. Dark: cards lighter than it.
    expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(light.colorScheme.surface, isNot(light.scaffoldBackgroundColor));
    expect(dark.colorScheme.surface.computeLuminance(),
        greaterThan(dark.scaffoldBackgroundColor.computeLuminance()));
  });

  test('dark cards have no borders; a raised card is one step lighter', () {
    final AppElevation e = dark.extension<AppElevation>()!;
    expect(e.level1.borderSide, BorderSide.none);
    expect(e.level2.borderSide, BorderSide.none);
    expect(e.level2.fill!.computeLuminance(),
        greaterThan(dark.colorScheme.surface.computeLuminance()));
  });

  test('light shadows are faint (alpha at most 6%)', () {
    final AppElevation e = light.extension<AppElevation>()!;
    for (final BoxShadow s in <BoxShadow>[
      ...e.level1.shadows,
      ...e.level2.shadows
    ]) {
      expect(s.color.a, lessThanOrEqualTo(0.06 + 1e-3));
    }
  });

  test('secondary is in the green family (selected segments are not brown)',
      () {
    for (final ThemeData t in <ThemeData>[light, dark]) {
      expect(greenTinted(t.colorScheme.secondaryContainer), isTrue);
    }
  });

  test('both themes carry the status, chart and elevation extensions', () {
    for (final ThemeData t in <ThemeData>[light, dark]) {
      expect(t.extension<AppStatusColors>(), isNotNull);
      expect(t.extension<AppChartColors>(), isNotNull);
      expect(t.extension<AppElevation>(), isNotNull);
    }
  });

  test('the five statuses are five different colours in each mode', () {
    for (final ThemeData t in <ThemeData>[light, dark]) {
      final AppStatusColors s = t.extension<AppStatusColors>()!;
      final Set<Color> bgs = <Color>{
        s.completedBackground,
        s.pendingBackground,
        s.overdueBackground,
        s.skippedBackground,
        s.infoBackground,
      };
      expect(bgs.length, 5);
    }
  });

  test('chart series are distinct from each other', () {
    for (final ThemeData t in <ThemeData>[light, dark]) {
      final AppChartColors c = t.extension<AppChartColors>()!;
      expect(<Color>{c.series, c.reference, c.alert, c.marker}.length, 4);
    }
  });

  test('extensions interpolate (theme switches animate)', () {
    final AppChartColors mid =
        AppChartColors.light.lerp(AppChartColors.dark, 0.5);
    expect(mid.series, Color.lerp(AppPalette.p40, AppPalette.pd80, 0.5));
    final AppStatusColors s =
        AppStatusColors.light.lerp(AppStatusColors.dark, 1);
    expect(s.infoBackground, AppStatusColors.dark.infoBackground);
  });
}
