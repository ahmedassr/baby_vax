import 'package:flutter/rendering.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/values/languages/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final String fsi = String.fromCharCode(0x2068);
  final String pdi = String.fromCharCode(0x2069);

  group('bidiIsolate', () {
    test('wraps text in FSI ... PDI', () {
      expect(bidiIsolate('BCG (1st dose)'), '${fsi}BCG (1st dose)$pdi');
      expect(bidiIsolate('ليلى'), '$fsiليلى$pdi');
    });

    test('leaves empty text alone and never double-wraps', () {
      expect(bidiIsolate(''), '');
      final String once = bidiIsolate('Lina');
      expect(bidiIsolate(once), once);
    });

    test('stripBidiIsolates undoes it', () {
      expect(stripBidiIsolates(bidiIsolate('a (b)')), 'a (b)');
    });
  });

  group('trIsolated', () {
    setUp(() => Get.addTranslations(AppTranslations().keys));
    tearDown(Get.reset);

    test('isolates every inserted value, not the sentence', () {
      Get.locale = const Locale('ar');
      final String body = 'Notification_vaccine_today_body'.trIsolated({
        'child': 'Lina',
        'vaccine': 'HPV Vaccine',
      });
      expect(body, contains('${fsi}Lina$pdi'));
      expect(body, contains('${fsi}HPV Vaccine$pdi'));
      expect(
          stripBidiIsolates(body),
          'Notification_vaccine_today_body'.trParams({
            'child': 'Lina',
            'vaccine': 'HPV Vaccine',
          }));
    });
  });

  testWidgets('an isolated LTR sentence keeps its full stop at its end in RTL',
      (tester) async {
    // Lay the same text out in an RTL paragraph, with and without the
    // isolate, and check where the final "." lands relative to the last
    // letter. (Brackets are already paired correctly by the bidi algorithm;
    // trailing punctuation is what goes wrong.)
    Future<(double, double)> positions(String text) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: Text(text, key: const Key('t'))),
      ));
      final RenderParagraph p =
          tester.renderObject<RenderParagraph>(find.byKey(const Key('t')));
      double xOf(int index) => p
          .getBoxesForSelection(
              TextSelection(baseOffset: index, extentOffset: index + 1))
          .first
          .left;
      final int letter = text.lastIndexOf('p');
      final int stop = text.lastIndexOf('.');
      return (xOf(letter), xOf(stop));
    }

    const String note = 'Dentist check-up.';
    final (double rawP, double rawStop) = await positions(note);
    final (double isoP, double isoStop) = await positions(bidiIsolate(note));

    // Without the isolate the "." is pulled to the far left of the line.
    expect(rawStop, lessThan(rawP));
    // With it, "." stays right after "check-up".
    expect(isoStop, greaterThan(isoP));
  });
}
