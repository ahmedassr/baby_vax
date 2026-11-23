// WCAG 2.1 contrast of every text/background pair the app draws, in both
// modes (polish §1.8). Text pairs must reach 4.5:1 (AA, normal text);
// non-text pairs (chart lines, outlines, focus rings) 3:1.
//
// With CONTRAST_TABLE=<path> it also writes the Markdown table that
// docs/design/v1.1-polish.md §4 quotes.

import 'dart:io';
import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

double _channel(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// The WCAG contrast ratio of [a] on [b] (both opaque).
double contrast(Color a, Color b) {
  final double la = luminance(a), lb = luminance(b);
  final double hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class Pair {
  const Pair(this.name, this.fg, this.bg, {this.text = true});
  final String name;
  final Color fg, bg;
  final bool text;
  double get ratio => contrast(fg, bg);
  double get minimum => text ? 4.5 : 3.0;
}

/// Every pair drawn in [theme].
List<Pair> pairsFor(ThemeData theme) {
  final ColorScheme s = theme.colorScheme;
  final AppStatusColors st = theme.extension<AppStatusColors>()!;
  final AppChartColors ch = theme.extension<AppChartColors>()!;
  final AppElevation el = theme.extension<AppElevation>()!;
  final Color page = theme.scaffoldBackgroundColor;
  final Color raised = el.level2.fill ?? s.surface;
  return <Pair>[
    Pair('Body text on page', s.onSurface, page),
    Pair('Body text on card', s.onSurface, s.surface),
    Pair('Body text on raised card', s.onSurface, raised),
    Pair('Secondary text on page', s.onSurfaceVariant, page),
    Pair('Secondary text on card', s.onSurfaceVariant, s.surface),
    Pair('Secondary text on raised card', s.onSurfaceVariant, raised),
    Pair('Secondary text on field / chip', s.onSurfaceVariant,
        s.surfaceContainer),
    Pair('Secondary text on highest fill', s.onSurfaceVariant,
        s.surfaceContainerHighest),
    Pair('Primary text / link on card', s.primary, s.surface),
    Pair('Primary text on page', s.primary, page),
    Pair('Primary text on raised card', s.primary, raised),
    Pair('Primary button label', s.onPrimary, s.primary),
    Pair('Tonal button / selected nav', s.onPrimaryContainer,
        s.primaryContainer),
    Pair('Selected segment', s.onSecondaryContainer, s.secondaryContainer),
    Pair('Secondary fill label', s.onSecondary, s.secondary),
    Pair('Info text on card', s.tertiary, s.surface),
    Pair('Info container', s.onTertiaryContainer, s.tertiaryContainer),
    Pair('Error text on card', s.error, s.surface),
    Pair('Error text on page', s.error, page),
    Pair('Error button label', s.onError, s.error),
    Pair('Error container', s.onErrorContainer, s.errorContainer),
    Pair('Snackbar text', s.onInverseSurface, s.inverseSurface),
    Pair('Snackbar action', s.inversePrimary, s.inverseSurface),
    Pair('Status: given', st.completedForeground, st.completedBackground),
    Pair('Status: due', st.pendingForeground, st.pendingBackground),
    Pair('Status: overdue', st.overdueForeground, st.overdueBackground),
    Pair('Status: skipped / warning', st.skippedForeground,
        st.skippedBackground),
    Pair('Status: info', st.infoForeground, st.infoBackground),
    Pair('Chart axis labels', ch.ink, s.surface),
    Pair('Chart: baby readings', ch.series, s.surface, text: false),
    Pair('Chart: WHO average', ch.reference, s.surface, text: false),
    Pair('Chart: fever line / outside', ch.alert, s.surface, text: false),
    Pair('Chart: medicine marker', ch.marker, s.surface, text: false),
    Pair('Chart: dose marker', ch.event, s.surface, text: false),
    Pair('Field outline (focused)', s.primary, s.surfaceContainer, text: false),
    Pair('Outline on card', s.outline, s.surface, text: false),
  ];
}

void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    'Light': AppTheme.lightTheme,
    'Dark': AppTheme.darkTheme,
  };

  for (final MapEntry<String, ThemeData> t in themes.entries) {
    test('${t.key}: every pair meets WCAG AA', () {
      final List<String> failing = <String>[
        for (final Pair p in pairsFor(t.value))
          if (p.ratio < p.minimum)
            '${p.name}: ${hex(p.fg)} on ${hex(p.bg)} = '
                '${p.ratio.toStringAsFixed(2)} (needs ${p.minimum})',
      ];
      expect(failing, isEmpty);
    });
  }

  test('the brand green is illustration only (too light for text)', () {
    expect(contrast(AppColors.brand, Colors.white), lessThan(4.5));
  });

  final String? out = Platform.environment['CONTRAST_TABLE'];
  test('writes the contrast table', skip: out == null, () {
    final List<Pair> light = pairsFor(AppTheme.lightTheme);
    final List<Pair> dark = pairsFor(AppTheme.darkTheme);
    final StringBuffer b = StringBuffer()
      ..writeln('| Pair | Min | Light (fg on bg) | Ratio | '
          'Dark (fg on bg) | Ratio |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (int i = 0; i < light.length; i++) {
      final Pair l = light[i], d = dark[i];
      b.writeln('| ${l.name} | ${l.minimum} | `${hex(l.fg)}` on `${hex(l.bg)}`'
          ' | ${l.ratio.toStringAsFixed(2)} | `${hex(d.fg)}` on '
          '`${hex(d.bg)}` | ${d.ratio.toStringAsFixed(2)} |');
    }
    File(out!).writeAsStringSync(b.toString());
  });
}
