// Prints the tonal palettes behind AppPalette (docs/design/v1.1-polish.md
// §1.2). Run from the repository root:
//
//   dart run tool/palette/tones.dart
//
// material_color_utilities ships with Flutter, so it is not a dependency of
// the app itself.
// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'package:material_color_utilities/material_color_utilities.dart';

String hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  const int brand = 0xFF42A332;
  final double hue = Hct.fromInt(brand).hue; // 141.9
  final Map<String, TonalPalette> palettes = <String, TonalPalette>{
    'primary (light)': TonalPalette.of(hue, 48),
    'primary (dark, containers)': TonalPalette.of(hue, 36),
    'secondary': TonalPalette.of(hue, 16),
    'neutral': TonalPalette.of(hue, 4),
    'neutral variant': TonalPalette.of(hue, 8),
    'error': TonalPalette.of(30, 70),
    'warning': TonalPalette.of(80, 50),
    // v1.1's info blue #1F6FA8, harmonised toward the brand (hue 233.4).
    'info': TonalPalette.of(
        Hct.fromInt(Blend.harmonize(0xFF1F6FA8, brand)).hue, 42),
  };
  const List<int> tones = <int>[
    4,
    6,
    10,
    12,
    17,
    20,
    22,
    24,
    30,
    40,
    50,
    60,
    80,
    90,
    92,
    94,
    95,
    96,
    100
  ];
  palettes.forEach((String name, TonalPalette p) {
    print('$name: ${tones.map((int t) => '$t=${hex(p.get(t))}').join(' ')}');
  });
}
