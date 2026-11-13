import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_date_details/widgets/dose_record_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(initializeDateFormatting);
  tearDown(Get.reset);

  /// Opens the sheet from a button and records what it returned.
  Future<List<DoseRecord?>> open(WidgetTester tester,
      {Variant variant = const Variant('en', Brightness.light, 1.0),
      DoseRecord initial = const DoseRecord(),
      bool editing = false}) async {
    final List<DoseRecord?> results = <DoseRecord?>[];
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => results.add(await DoseRecordSheet.show(
                  initial: initial, today: fixedNow, editing: editing)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      variant: variant,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  for (final Variant v in mainVariants) {
    testWidgets('fits a small screen ($v)', (tester) async {
      await open(tester, variant: v);
      expect(find.text('Record_sheet_title'.tr), findsOneWidget);
      expectNoOverflow(tester);
    });
  }

  testWidgets('save returns a trimmed record dated today by default',
      (tester) async {
    final results = await open(tester);
    await tester.enterText(field('record_clinic'), '  Ramallah MCH ');
    await tester.enterText(field('record_lot'), 'AB1234');
    await tester.ensureVisible(find.byKey(const Key('record_save')));
    await tester.tap(find.byKey(const Key('record_save')));
    await tester.pumpAndSettle();
    final DoseRecord r = results.single!;
    expect(r.clinic, 'Ramallah MCH');
    expect(r.lot, 'AB1234');
    expect(r.note, isNull);
    expect(r.givenDate, DateTime(2027, 3, 10));
  });

  testWidgets('"without details" returns an empty record', (tester) async {
    final results = await open(tester);
    await tester.ensureVisible(find.byKey(const Key('record_without_details')));
    await tester.tap(find.byKey(const Key('record_without_details')));
    await tester.pumpAndSettle();
    expect(results.single!.isEmpty, isTrue);
  });

  testWidgets('editing pre-fills and has no "without details"', (tester) async {
    await open(tester,
        editing: true, initial: const DoseRecord(lot: 'XY9', note: 'ok'));
    expect(find.text('XY9'), findsOneWidget);
    expect(find.byKey(const Key('record_without_details')), findsNothing);
  });

  testWidgets('labels and tap targets', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await expectLabelledTargets(tester);
    handle.dispose();
  });
}
