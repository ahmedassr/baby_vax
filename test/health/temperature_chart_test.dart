import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:baby_vax/app/modules/health/view/health_view.dart';
import 'package:baby_vax/app/modules/health/widgets/health_entry_sheet.dart';
import 'package:baby_vax/app/modules/health/widgets/temperature_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';
import 'health_controller_test.dart' show FakeHealthStore;

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  HealthEntry temp(String id, Duration ago, double c,
          [TemperatureMethod m = TemperatureMethod.armpit]) =>
      HealthEntry(
          id: id,
          kind: HealthEntryKind.temperature,
          at: fixedNow.subtract(ago),
          tempC: c,
          method: m);

  // fixedNow is 10 Mar 2027, noon.
  List<HealthEntry> sample() => <HealthEntry>[
        temp('old', const Duration(days: 12), 36.8),
        temp('wk', const Duration(days: 5), 37.1),
        temp('t1', const Duration(hours: 26), 37.0),
        temp('t2', const Duration(hours: 2), 38.1),
        HealthEntry(
            id: 'm1',
            kind: HealthEntryKind.medicine,
            at: fixedNow.subtract(const Duration(hours: 3)),
            medicine: 'Paracetamol',
            amount: '2.5 ml'),
      ];

  /// The 2-month doses given yesterday. (The birth dose, given on 15 Jan,
  /// is outside every period.)
  List<MedicalDatesModel> doses() {
    final List<MedicalDatesModel> s = sampleSchedule();
    s[1] = s[1].copyWith(
        state: 'Completed',
        record: DoseRecord(givenDate: DateTime(2027, 3, 9)));
    return s;
  }

  HealthController put({List<HealthEntry>? entries}) {
    final HealthController c =
        FakeHealthStore(entries ?? sample()).controller(doses: doses());
    Get.put<HealthController>(c);
    return c;
  }

  group('HealthController chart period', () {
    test('3, 7 and 30 days', () async {
      final HealthController c = put();
      await c.fetch();
      expect(c.chartDays.value, 3);
      expect(c.chartFrom, DateTime(2027, 3, 8));
      expect(c.chartTemperatures.map((e) => e.id), <String>['t1', 't2']);
      expect(c.chartMedicines.map((e) => e.id), <String>['m1']);
      expect(c.chartDoses.single.dose.id, doses()[1].id);
      expect(c.chartDoses.single.at, DateTime(2027, 3, 9, 12));
      c.setChartDays(7);
      expect(c.chartTemperatures.map((e) => e.id), <String>['wk', 't1', 't2']);
      c.setChartDays(30);
      expect(c.chartTemperatures.map((e) => e.id),
          <String>['old', 'wk', 't1', 't2']);
    });
  });

  Future<void> pump(WidgetTester tester, Variant v) async {
    await pumpApp(tester, const Scaffold(body: HealthView()), variant: v);
    await tester.pumpAndSettle();
  }

  TemperatureChartState chartState(WidgetTester tester) =>
      tester.state<TemperatureChartState>(find.byType(TemperatureChart));

  Future<void> tapAt(WidgetTester tester, Offset local) async {
    final Offset origin =
        tester.getTopLeft(find.byKey(const Key('health_chart_tap')));
    await tester.tapAt(origin + local);
    await tester.pumpAndSettle();
  }

  group('Temperature card', () {
    for (final Variant v in mainVariants) {
      testWidgets('at the top, time left to right, switch, fits ($v)',
          (tester) async {
        final HealthController c = put();
        await pump(tester, v);
        expect(
            find.byKey(const Key('health_temperature_card')), findsOneWidget);
        expect(
            tester
                .getTopLeft(find.byKey(const Key('health_temperature_card')))
                .dy,
            lessThan(100),
            reason: 'the first thing on the tab');
        final List<Offset> o = chartState(tester).readingOffsets;
        expect(o, hasLength(2));
        expect(o[0].dx, lessThan(o[1].dx), reason: 'not mirrored in $v');
        expect(chartState(tester).doseOffsets, hasLength(1));
        expect(chartState(tester).medicineOffsets, hasLength(1));
        expectNoOverflow(tester);

        await tester.tap(find.byKey(const Key('health_chart_days_30')));
        await tester.pumpAndSettle();
        expect(c.chartDays.value, 30);
        expect(chartState(tester).readingOffsets, hasLength(4));
        expectNoOverflow(tester);
      });
    }

    testWidgets('the fever line is WHO\'s pinned figure, cited',
        (tester) async {
      put();
      await pump(tester, const Variant('en', Brightness.light, 1.0));
      final String source = tester
          .widget<Text>(find.byKey(const Key('health_chart_source')))
          .data!;
      expect(source, contains('${HealthGuidance.feverArmpitC} °C'));
      expect(source, contains('${HealthGuidance.rectalOffsetC} °C higher'));
      expect(source, contains('WHO IMCI'));
      expect(TemperatureChart.isFever(sample()[3]), isTrue);
      expect(TemperatureChart.isFever(sample()[2]), isFalse);
    });

    testWidgets('tap a reading: its entry, and Open edits it', (tester) async {
      put();
      await pump(tester, const Variant('en', Brightness.light, 1.0));
      await tapAt(tester, chartState(tester).readingOffsets[1]);
      expect(find.byKey(const Key('health_chart_details')), findsOneWidget);
      expect(find.textContaining('38.1 °C'), findsWidgets);
      await tester.tap(find.byKey(const Key('health_chart_open')));
      await tester.pumpAndSettle();
      expect(find.byType(HealthEntrySheet), findsOneWidget);
      expect(
          tester
              .widget<HealthEntrySheet>(find.byType(HealthEntrySheet))
              .initial!
              .id,
          't2');
    });

    testWidgets('tap a dose marker: the vaccine, and Open shows the dose',
        (tester) async {
      put();
      await pump(tester, const Variant('en', Brightness.light, 1.0));
      await tapAt(tester, chartState(tester).doseOffsets.single);
      expect(find.textContaining('Vaccine given:'), findsOneWidget);
      await tester.tap(find.byKey(const Key('health_chart_open')));
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.medicalDateDetails), findsOneWidget);
    });

    testWidgets('tap a medicine marker: name and amount', (tester) async {
      put();
      await pump(tester, const Variant('ar', Brightness.dark, 1.3));
      await tapAt(tester, chartState(tester).medicineOffsets.single);
      expect(find.textContaining('Paracetamol'), findsWidgets);
      expectNoOverflow(tester);
    });

    for (final Variant v in mainVariants) {
      testWidgets('empty period: a message and a way to log ($v)',
          (tester) async {
        put(entries: <HealthEntry>[temp('old', const Duration(days: 12), 37)]);
        await pump(tester, v);
        expect(find.byKey(const Key('health_chart_empty')), findsOneWidget);
        expect(find.byType(TemperatureChart), findsNothing);
        expectNoOverflow(tester);
        await tester.tap(find.byKey(const Key('health_chart_add')));
        await tester.pumpAndSettle();
        expect(find.byType(HealthEntrySheet), findsOneWidget);
      });
    }

    testWidgets('Arabic plural forms for the periods', (tester) async {
      put(entries: <HealthEntry>[]);
      await pump(tester, const Variant('ar', Brightness.light, 1.0));
      expect(find.text('3 أيام'), findsOneWidget);
      expect(find.text('30 يومًا'), findsOneWidget);
      expect(find.textContaining('آخر 3 أيام'), findsOneWidget);
    });

    testWidgets('one reading: the chart and a hint', (tester) async {
      put(entries: <HealthEntry>[temp('a', const Duration(hours: 1), 37)]);
      await pump(tester, const Variant('en', Brightness.light, 1.0));
      expect(find.byKey(const Key('health_chart_one')), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pump(tester, const Variant('ar', Brightness.dark, 1.3));
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
