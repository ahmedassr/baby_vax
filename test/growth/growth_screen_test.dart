import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/growth/widgets/measurement_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  // Born 15 Jan 2027 (sampleUser), measured at birth and at about 2 months.
  final List<MeasurementModel> sample = <MeasurementModel>[
    MeasurementModel(
        id: 'm1', date: DateTime(2027, 1, 15), weightKg: 3.2, heightCm: 49.1),
    MeasurementModel(
        id: 'm2',
        date: DateTime(2027, 3, 10),
        weightKg: 5.0,
        headCm: 38.3,
        note: 'Clinic'),
  ];

  late List<MeasurementModel> store;
  late List<Map<String, String>> profileWrites;

  GrowthController put(
      {String? sex = 'female', List<MeasurementModel>? items}) {
    store = List<MeasurementModel>.of(items ?? sample);
    profileWrites = <Map<String, String>>[];
    final c = GrowthController(
      load: (_) async => List<MeasurementModel>.of(store),
      save: (_, m) async {
        final MeasurementModel saved = m.copyWith(id: m.id ?? 'new');
        store.removeWhere((x) => x.id == saved.id);
        store.add(saved);
        return WriteOutcome.synced;
      },
      delete: (_, id) async => store.removeWhere((x) => x.id == id),
      updateProfile: (_, f) async => profileWrites.add(f),
      user: () => sampleUser(sex: sex),
      clock: () => fixedNow,
    );
    Get.put<GrowthController>(c);
    return c;
  }

  group('GrowthController', () {
    test('loads newest first; series per metric oldest first', () async {
      final c = put();
      await c.fetch();
      expect(c.items.first.id, 'm2');
      expect(c.series.map((m) => m.id), <String>['m1', 'm2']);
      c.setMetric(GrowthMetric.head);
      expect(c.series.map((m) => m.id), <String>['m2']);
    });

    test('latest reading is placed on the WHO reference', () async {
      final c = put();
      await c.fetch();
      expect(c.latestReading, isNotNull);
      expect(c.latestReading!.percentile, inInclusiveRange(0, 100));
    });

    test('no reading without the sex', () async {
      final c = put(sex: null);
      await c.fetch();
      expect(c.latestReading, isNull);
      expect(c.percentilesAvailable, isFalse);
    });

    test('saving copies the newest value of each metric to the profile',
        () async {
      final c = put();
      await c.fetch();
      await c.saveMeasurement(
          MeasurementModel(date: DateTime(2027, 3, 10), heightCm: 57));
      expect(profileWrites.last,
          <String, String>{'weight': '5', 'height': '57', 'headSize': '38.3'});
    });

    test('deleting re-derives the profile values', () async {
      final c = put();
      await c.fetch();
      await c.deleteMeasurement(sample[1]);
      expect(c.items, hasLength(1));
      expect(profileWrites.last,
          <String, String>{'weight': '3.2', 'height': '49.1'});
    });

    test('an empty measurement is never saved', () async {
      final c = put(items: <MeasurementModel>[]);
      expect(
          await c.saveMeasurement(MeasurementModel(date: DateTime(2027, 3, 1))),
          isFalse);
      expect(store, isEmpty);
    });
  });

  group('GrowthView', () {
    for (final Variant v in mainVariants) {
      testWidgets('chart, reading and history fit ($v)', (tester) async {
        put();
        await pumpApp(tester, const GrowthView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('growth_chart')), findsOneWidget);
        expect(find.byKey(const Key('growth_reading_text')), findsOneWidget);
        expectNoOverflow(tester);
        await tester.scrollUntilVisible(find.byType(MedicalDisclaimer), 300,
            scrollable: find.byType(Scrollable).first);
        expectNoOverflow(tester);
      });
    }

    testWidgets('reading in plain words, never a diagnosis', (tester) async {
      put();
      await pumpApp(tester, const GrowthView());
      await tester.pumpAndSettle();
      final Text t =
          tester.widget<Text>(find.byKey(const Key('growth_reading_text')));
      expect(
          t.data,
          matches(RegExp(
              r'^(Around the \d+(st|nd|rd|th)|Below the 3rd|Above the 97th) percentile$')));
      expect(find.textContaining('not a diagnosis'), findsOneWidget);
    });

    testWidgets('Arabic reading uses the bare number', (tester) async {
      put();
      await pumpApp(tester, const GrowthView(),
          variant: const Variant('ar', Brightness.light, 1.0));
      await tester.pumpAndSettle();
      final Text t =
          tester.widget<Text>(find.byKey(const Key('growth_reading_text')));
      expect(
          t.data,
          anyOf(
              startsWith('حول المئين'), startsWith('أقل'), startsWith('أعلى')));
      expect(RegExp('[٠-٩]').hasMatch(t.data!), isFalse);
    });

    testWidgets('without the sex: a prompt, no curves', (tester) async {
      put(sex: null);
      await pumpApp(tester, const GrowthView());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('growth_no_sex')), findsOneWidget);
      expect(find.byKey(const Key('growth_reading_text')), findsNothing);
    });

    testWidgets('empty state offers to add', (tester) async {
      put(items: <MeasurementModel>[]);
      await pumpApp(tester, const GrowthView());
      await tester.pumpAndSettle();
      expect(find.text('No measurements yet'), findsOneWidget);
    });

    testWidgets('metric tiles switch the chart', (tester) async {
      final c = put();
      await pumpApp(tester, const GrowthView());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('growth_metric_height')));
      await tester.pump();
      expect(c.metric.value, GrowthMetric.height);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pumpApp(tester, const GrowthView());
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('MeasurementSheet', () {
    Future<List<MeasurementSheetResult?>> open(WidgetTester tester,
        {MeasurementModel? initial, Variant? variant}) async {
      final List<MeasurementSheetResult?> out = <MeasurementSheetResult?>[];
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => out.add(await MeasurementSheet.show(
                  today: fixedNow,
                  initial: initial,
                  birthDate: DateTime(2027, 1, 15))),
              child: const Text('open'),
            ),
          ),
        ),
        variant: variant ?? const Variant('en', Brightness.light, 1.0),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return out;
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('growth_save')));
      await tester.tap(find.byKey(const Key('growth_save')));
      await tester.pumpAndSettle();
    }

    for (final Variant v in mainVariants) {
      testWidgets('fits ($v)', (tester) async {
        await open(tester, variant: v);
        expectNoOverflow(tester);
      });
    }

    testWidgets('needs at least one value', (tester) async {
      final out = await open(tester);
      await save(tester);
      expect(find.byKey(const Key('growth_form_error')), findsOneWidget);
      expect(out, isEmpty);
    });

    testWidgets('rejects a weight in grams, accepts "4,6"', (tester) async {
      final out = await open(tester);
      await tester.enterText(field('growth_weight'), '4600');
      await save(tester);
      expect(out, isEmpty);
      await tester.enterText(field('growth_weight'), '4,6');
      await save(tester);
      final r = out.single as SaveMeasurement;
      expect(r.measurement.weightKg, 4.6);
      expect(r.measurement.date, fixedNow);
    });

    testWidgets('editing offers delete', (tester) async {
      final out = await open(tester, initial: sample[1]);
      expect(find.text('38.3'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('growth_delete')));
      await tester.tap(find.byKey(const Key('growth_delete')));
      await tester.pumpAndSettle();
      expect(out.single, isA<DeleteMeasurement>());
    });
  });
}
