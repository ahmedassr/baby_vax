// Phone review R1: "System" wrapped mid-word ("Syste m") in Settings >
// Appearance. Choice groups now measure their labels and either sit side
// by side with single-line labels or stack. Checked with the real Cairo
// font, so the widths are the phone's.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Every choice group in the app, with its labels and preferred columns.
final Map<String, (List<String>, int)> groups = <String, (List<String>, int)>{
  'theme (settings)': (
    <String>[
      "Settings_theme_system",
      "AppSettingDarkModeSwitch_light_mode_label",
      "AppSettingDarkModeSwitch_dark_mode_label",
    ],
    3
  ),
  'sex (sign-up, profile)': (<String>["sex_female", "sex_male"], 2),
  'repeat (reminder sheet)': (
    <String>[
      "Reminders_repeat_none",
      "Reminders_repeat_daily",
      "Reminders_repeat_weekly",
      "Reminders_repeat_monthly",
    ],
    2
  ),
  'metric (growth)': (
    <String>["weight_label", "height_label", "head_size_label"],
    3
  ),
};

/// Every main variant, plus English light at 1.3.
const List<Variant> variants = <Variant>[
  ...mainVariants,
  Variant('en', Brightness.light, 1.3),
];

void main() {
  tearDown(Get.reset);

  group('columnsFor', () {
    test('side by side when the widest label fits its share', () {
      expect(
          AppChoiceGroup.columnsFor(
              width: 328, widestLabel: 60, count: 3, preferred: 3),
          3);
    });
    test('stacks rather than leaving a lone tile', () {
      // 3 do not fit; 2 would leave one alone on the last row.
      expect(
          AppChoiceGroup.columnsFor(
              width: 328, widestLabel: 120, count: 3, preferred: 3),
          1);
    });
    test('four options fall back to two per row, then one', () {
      expect(
          AppChoiceGroup.columnsFor(
              width: 328, widestLabel: 120, count: 4, preferred: 4),
          2);
      expect(
          AppChoiceGroup.columnsFor(
              width: 328, widestLabel: 200, count: 4, preferred: 2),
          1);
    });
  });

  for (final Variant v in variants) {
    testWidgets(
        'Settings > Appearance: no word broken, labels on one line '
        '($v)', (tester) async {
      Get.put<SettingsController>(SettingsController(
        write: (k, v) async {},
        remove: (_) {},
        notificationsEnabled: () async => true,
        applyLocale: (_) async {},
      ));
      await pumpApp(tester, const Scaffold(body: SettingsView()), variant: v);
      await tester.pumpAndSettle();
      final Finder group = find.byType(AppChoiceGroup<ThemeMode>);
      expect(group, findsOneWidget);
      expectNoBrokenWords(tester, within: group);
      expectNoOverflow(tester);

      // Side by side at 360dp: every label is one line, and the three
      // tiles share a row.
      final List<double> tops = <double>[
        for (final String m in <String>['system', 'light', 'dark'])
          tester.getTopLeft(find.byKey(Key('theme_$m'))).dy,
      ];
      expect(tops.toSet(), hasLength(1), reason: 'one row at 360dp');
      for (final Element e in find
          .descendant(of: group, matching: find.byType(RichText))
          .evaluate()) {
        final RenderParagraph p = e.renderObject! as RenderParagraph;
        final String t = p.text.toPlainText();
        expect(
            spansLines(p.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: t.length))),
            isFalse,
            reason: '"$t" on one line');
      }

      // Selection still works and is shown with a check, not colour alone.
      await tester.tap(find.byKey(const Key('theme_system')));
      await tester.pump();
      expect(
          find.descendant(
              of: find.byKey(const Key('theme_system')),
              matching: find.byIcon(Icons.check_circle_rounded)),
          findsOneWidget);
    });
  }

  for (final MapEntry<String, (List<String>, int)> g in groups.entries) {
    for (final Variant v in variants) {
      for (final double width in <double>[360, 280]) {
        testWidgets('${g.key} at ${width.toInt()}dp: no word broken ($v)',
            (tester) async {
          int? selected = 0;
          await pumpApp(
            tester,
            Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => Padding(
                  // A sheet's side padding, the widest the app uses.
                  padding: AppSpacing.sheet,
                  child: AppChoiceGroup<int>(
                    columns: g.value.$2,
                    selected: selected,
                    onSelected: (i) => setState(() => selected = i),
                    options: <AppChoiceOption<int>>[
                      for (int i = 0; i < g.value.$1.length; i++)
                        AppChoiceOption<int>(
                          key: Key('o$i'),
                          value: i,
                          label: g.value.$1[i].tr,
                          icon: Icons.circle_outlined,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            variant: v,
            size: Size(width, 640),
          );
          expectNoBrokenWords(tester);
          expectNoOverflow(tester);
          for (int i = 0; i < g.value.$1.length; i++) {
            final Size s = tester.getSize(find.byKey(Key('o$i')));
            expect(s.height, greaterThanOrEqualTo(56));
          }
          await tester.tap(find.byKey(const Key('o1')));
          await tester.pump();
          expect(selected, 1);
        });
      }
    }
  }

  testWidgets('stacks one per row, full width, when there is no room',
      (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: AppChoiceGroup<int>(
          selected: 0,
          onSelected: (_) {},
          options: const <AppChoiceOption<int>>[
            AppChoiceOption<int>(
                key: Key('a'), value: 0, label: 'Automatic', icon: Icons.abc),
            AppChoiceOption<int>(
                key: Key('b'),
                value: 1,
                label: 'Always light',
                icon: Icons.abc),
            AppChoiceOption<int>(
                key: Key('c'), value: 2, label: 'Always dark', icon: Icons.abc),
          ],
        ),
      ),
      variant: const Variant('en', Brightness.light, 1.3),
      size: const Size(220, 640),
    );
    final Rect a = tester.getRect(find.byKey(const Key('a')));
    final Rect b = tester.getRect(find.byKey(const Key('b')));
    expect(b.top, greaterThan(a.bottom), reason: 'stacked');
    expect(a.width, 220);
    expectNoBrokenWords(tester);
    expectNoOverflow(tester);
  });
}
