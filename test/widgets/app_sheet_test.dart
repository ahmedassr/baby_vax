// Phone review R2: sheets were see-through (get's bottomSheet forced a
// transparent background). Every sheet now opens through AppSheet.show and
// takes an opaque surface, a drag handle and a scrim from the theme.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/growth/widgets/measurement_sheet.dart';
import 'package:baby_vax/app/modules/medical_date_details/widgets/dose_record_sheet.dart';
import 'package:baby_vax/app/modules/reminders/widgets/reminder_sheet.dart';
import 'package:baby_vax/app/modules/vaccination_card/vaccination_card_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);
  tearDown(Get.reset);

  final Map<String, Future<Object?> Function()> sheets =
      <String, Future<Object?> Function()>{
    'reminder': () => ReminderSheet.show(now: fixedNow),
    'measurement': () => MeasurementSheet.show(today: fixedNow),
    'dose record': () =>
        DoseRecordSheet.show(initial: const DoseRecord(), today: fixedNow),
    'vaccination card': () => VaccinationCardSheet.show(),
  };

  Future<void> open(
      WidgetTester tester, Future<Object?> Function() show, Variant v) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Column(children: <Widget>[
          // What used to show through the reminder form.
          const Text('BEHIND'),
          TextButton(onPressed: show, child: const Text('open')),
        ]),
      ),
      variant: v,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final Variant v in const <Variant>[
    Variant('en', Brightness.light, 1.0),
    Variant('ar', Brightness.dark, 1.3),
  ]) {
    for (final MapEntry<String, Future<Object?> Function()> s
        in sheets.entries) {
      testWidgets('${s.key} sheet is opaque, has a handle and a scrim ($v)',
          (tester) async {
        await open(tester, s.value, v);
        final ThemeData theme = Theme.of(tester.element(find.text('BEHIND')));
        final ColorScheme scheme = theme.colorScheme;

        final Finder sheet = find.byType(BottomSheet);
        expect(sheet, findsOneWidget);
        final Material surface = tester.widget<Material>(
            find.descendant(of: sheet, matching: find.byType(Material)).first);
        expect(surface.color, scheme.surface);
        expect(surface.color!.a, 1.0, reason: 'sheet must be opaque');
        expect(scheme.surface.a, 1.0);

        // The drag handle (announced as "Dismiss" by TalkBack).
        expect(
            find.descendant(
                of: sheet,
                matching: find.bySemanticsLabel(
                    MaterialLocalizations.of(tester.element(sheet))
                        .modalBarrierDismissLabel)),
            findsOneWidget);

        // The scrim dims the screen behind.
        final Iterable<ModalBarrier> barriers =
            tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
        expect(barriers.map((b) => b.color),
            contains(AppTheme.sheetScrim(scheme)));
        expect(AppTheme.sheetScrim(scheme).a, greaterThan(0.3));
        expectNoOverflow(tester);
      });
    }
  }

  test('both themes give sheets an opaque surface and a handle', () {
    for (final ThemeData t in <ThemeData>[
      AppTheme.lightTheme,
      AppTheme.darkTheme
    ]) {
      final BottomSheetThemeData s = t.bottomSheetTheme;
      expect(s.modalBackgroundColor, t.colorScheme.surface);
      expect(s.modalBackgroundColor!.a, 1.0);
      expect(s.showDragHandle, isTrue);
      expect(s.modalBarrierColor, AppTheme.sheetScrim(t.colorScheme));
    }
  });
}
