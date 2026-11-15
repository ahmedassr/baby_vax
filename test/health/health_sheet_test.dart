import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:baby_vax/app/modules/health/widgets/health_entry_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(initializeDateFormatting);
  tearDown(Get.reset);

  /// Born 15 Jan 2027: on [fixedNow] (10 Mar) a young infant.
  final DateTime young = DateTime(2027, 1, 15);
  final DateTime older = DateTime(2026, 6, 1);

  Future<List<HealthSheetResult?>> open(
    WidgetTester tester,
    HealthEntryKind kind, {
    Variant variant = const Variant('en', Brightness.light, 1.0),
    HealthEntry? initial,
    DateTime? birthDate,
  }) async {
    final List<HealthSheetResult?> out = <HealthSheetResult?>[];
    await pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async => out.add(await HealthEntrySheet.show(
                kind: kind,
                now: fixedNow,
                initial: initial,
                birthDate: birthDate ?? older)),
            child: const Text('open'),
          ),
        ),
      ),
      variant: variant,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return out;
  }

  Future<void> save(WidgetTester tester) async {
    // Let a focused field finish scrolling itself into view first.
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_save')));
    await tester.pumpAndSettle();
  }

  for (final Variant v in mainVariants) {
    for (final HealthEntryKind k in HealthEntryKind.values) {
      testWidgets('${k.name} sheet fits ($v)', (tester) async {
        await open(tester, k, variant: v);
        expect(find.text("Health_add_${k.name}".tr), findsOneWidget);
        expect(find.byType(MedicalDisclaimer), findsOneWidget);
        expectNoOverflow(tester);
        await tester.ensureVisible(find.byKey(const Key('health_save')));
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
      });
    }
  }

  group('temperature', () {
    testWidgets('accepts "38,4" and returns it with the method',
        (tester) async {
      final out = await open(tester, HealthEntryKind.temperature);
      await tester.enterText(field('health_temp'), '38,4');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('health_method_rectal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('health_method_rectal')));
      await save(tester);
      final HealthEntry e = (out.single! as SaveHealthEntry).entry;
      expect(e.tempC, 38.4);
      expect(e.method, TemperatureMethod.rectal);
      expect(e.at, fixedNow);
    });

    testWidgets('a reading in °F is refused with an explanation',
        (tester) async {
      final out = await open(tester, HealthEntryKind.temperature);
      await tester.enterText(field('health_temp'), '100.4');
      await save(tester);
      expect(out, isEmpty);
      expect(find.byKey(const Key('health_form_error')), findsOneWidget);
    });

    testWidgets('young infant with 37.6 °C (armpit): urgent, WHO wording',
        (tester) async {
      await open(tester, HealthEntryKind.temperature, birthDate: young);
      await tester.enterText(field('health_temp'), '37.6');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('health_care_urgent')), findsOneWidget);
      expect(find.byKey(const Key('health_fever')), findsOneWidget);
    });

    testWidgets('older child with 38.0 °C: see a health worker',
        (tester) async {
      await open(tester, HealthEntryKind.temperature);
      await tester.enterText(field('health_temp'), '38.0');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('health_care_see')), findsOneWidget);
      expect(find.byKey(const Key('health_care_urgent')), findsNothing);
    });

    testWidgets('"other" method: no judgement, and says why', (tester) async {
      await open(tester, HealthEntryKind.temperature, birthDate: young);
      await tester.enterText(field('health_temp'), '39');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('health_method_other')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('health_method_other')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('health_care_urgent')), findsNothing);
      expect(find.text("Health_method_other_hint".tr), findsOneWidget);
    });

    testWidgets('Arabic: the figures use Western digits', (tester) async {
      await open(tester, HealthEntryKind.temperature,
          variant: const Variant('ar', Brightness.dark, 1.3));
      final String hint = tester
          .widget<Text>(find.byKey(const Key('health_method_hint')))
          .data!;
      expect(hint, contains('37.5'));
      expect(RegExp('[٠-٩]').hasMatch(hint), isFalse);
    });
  });

  group('signs', () {
    testWidgets('a danger sign is urgent; the picks come back in order',
        (tester) async {
      final out = await open(tester, HealthEntryKind.symptoms);
      await tester.tap(find.byKey(const Key('health_symptom_cough')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('health_care_urgent')), findsNothing);
      final Finder fits = find.byKey(const Key('health_symptom_convulsions'));
      await tester.ensureVisible(fits);
      await tester.pumpAndSettle();
      await tester.tap(fits);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('health_care_urgent')), findsOneWidget);
      await save(tester);
      expect((out.single! as SaveHealthEntry).entry.symptoms,
          <HealthSymptom>[HealthSymptom.cough, HealthSymptom.convulsions]);
    });

    testWidgets('nothing ticked is refused', (tester) async {
      final out = await open(tester, HealthEntryKind.symptoms);
      await save(tester);
      expect(out, isEmpty);
      expect(find.text("Health_symptoms_error".tr), findsOneWidget);
    });
  });

  testWidgets('medicine: name and amount as written; never advice',
      (tester) async {
    final out = await open(tester, HealthEntryKind.medicine);
    expect(find.byKey(const Key('health_no_advice')), findsOneWidget);
    await tester.enterText(field('health_medicine'), 'Paracetamol');
    await tester.enterText(field('health_amount'), '2.5 ml');
    await save(tester);
    final HealthEntry e = (out.single! as SaveHealthEntry).entry;
    expect(e.medicine, 'Paracetamol');
    expect(e.amount, '2.5 ml');
  });

  testWidgets('editing offers delete', (tester) async {
    final out = await open(tester, HealthEntryKind.note,
        initial: HealthEntry(
            id: 'x', kind: HealthEntryKind.note, at: fixedNow, note: 'Fine'));
    expect(find.text("Health_edit_title".tr), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('health_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_delete')));
    await tester.pumpAndSettle();
    expect(out.single, isA<DeleteHealthEntry>());
  });
}
