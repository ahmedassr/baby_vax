// Guards the design system: screens and shared widgets take colour and type
// from the theme, never from literals. A raw colour or font size that slips
// back into lib/app/modules or lib/app/core/widget fails here with the file
// and line, instead of being found on a phone in dark mode.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lines in [dirs] matching [pattern], skipping comments.
List<String> offenders(List<String> dirs, RegExp pattern) {
  final List<String> hits = <String>[];
  for (final String dir in dirs) {
    for (final File f in Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final List<String> lines = f.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String code = lines[i].split('//').first;
        if (pattern.hasMatch(code)) {
          hits.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }
  return hits;
}

void main() {
  const List<String> ui = <String>['lib/app/modules', 'lib/app/core/widget'];

  test('no raw colour literals in screens or shared widgets', () {
    expect(offenders(ui, RegExp(r'Color\(0x')), isEmpty);
  });

  test('no Material palette colours (Colors.green, Colors.grey…)', () {
    // Colors.transparent is not a colour choice.
    expect(offenders(ui, RegExp(r'\bColors\.(?!transparent\b)[a-z]')), isEmpty);
  });

  test('no literal font sizes in screens', () {
    expect(offenders(<String>['lib/app/modules'], RegExp(r'fontSize:\s*[0-9]')),
        isEmpty);
  });

  test('no light/dark branching in widgets; the theme carries both', () {
    expect(
        offenders(
            ui,
            RegExp(
                r'context\.isDarkMode|isDarkMode\s*\?|Brightness\.dark\s*\?')),
        isEmpty);
  });

  test('screens do not use the brand colours directly', () {
    // AppColors.brand is for illustration, which lives in assets/branding.
    expect(offenders(<String>['lib/app/modules'], RegExp(r'AppColors\.')),
        isEmpty);
  });

  test('no ScreenUtil units anywhere', () {
    expect(
        offenders(<String>['lib'],
            RegExp(r'\d\.(w|h|r|sp)\b|ScreenUtil|flutter_screenutil')),
        isEmpty);
  });
}
