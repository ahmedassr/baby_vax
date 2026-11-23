import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/widgets/growth_chart.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/home/view/home_view.dart';
import 'package:baby_vax/app/modules/home/widgets/home_growth_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  final List<MeasurementModel> sample = <MeasurementModel>[
    MeasurementModel(
        id: 'm1', date: DateTime(2027, 1, 15), weightKg: 3.2, heightCm: 49.1),
    MeasurementModel(id: 'm2', date: DateTime(2027, 2, 10), weightKg: 4.1),
    MeasurementModel(
        id: 'm3', date: DateTime(2027, 3, 9), weightKg: 4.9, heightCm: 56),
  ];

  HomeController putHome({List<MeasurementModel>? items}) {
    final c = HomeController(
      notificationsEnabled: () async => true,
      loadUser: (_) async => sampleUser(),
      loadDoses: (_) async => sampleSchedule(),
      loadMeasurements: (_) async => items ?? sample,
      clock: () => fixedNow,
    );
    Get.put<HomeController>(c);
    return c;
  }

  Future<void> showCard(WidgetTester tester, Variant v) async {
    await pumpApp(tester, const Scaffold(body: HomeView()), variant: v);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('home_growth_card')), 200);
    await tester.pumpAndSettle();
  }

  test('change since the previous measurement', () {
    Get.testMode = true;
    expect(HomeGrowthCard.changeText(GrowthMetric.weight, sample.sublist(0, 1)),
        isNull);
  });

  group('HomeGrowthCard', () {
    for (final Variant v in mainVariants) {
      testWidgets('switch, latest value, change, chart ($v)', (tester) async {
        putHome();
        await showCard(tester, v);
        expect(find.byKey(const Key('home_growth_chart')), findsOneWidget);
        // Weight: 4.9 kg, +0.8 since Feb 10.
        expect(
            find.descendant(
                of: find.byKey(const Key('home_growth_latest')),
                matching: find.textContaining('4.9', findRichText: true)),
            findsOneWidget);
        final String change = stripBidiIsolates(tester
            .widget<Text>(find.byKey(const Key('home_growth_change')))
            .data!);
        expect(change, contains('+0.8'));
        expect(RegExp('[٠-٩]').hasMatch(change), isFalse);
        expectNoOverflow(tester);

        await tester.tap(find.byKey(const Key('home_growth_height')));
        await tester.pumpAndSettle();
        final GrowthChart chart = tester
            .widget<GrowthChart>(find.byKey(const Key('home_growth_chart')));
        expect(chart.metric, GrowthMetric.height);
        expect(chart.unit, "unit_cm".tr);
        expect(chart.points.map((p) => p.value), <double>[49.1, 56]);
        expectNoOverflow(tester);

        // Head: none measured.
        await tester.tap(find.byKey(const Key('home_growth_head')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home_growth_chart')), findsNothing);
        expect(find.byKey(const Key('home_growth_none')), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('one unit per chart: each measure has its own axis',
        (tester) async {
      putHome();
      await showCard(tester, const Variant('en', Brightness.light, 1.0));
      GrowthChart chart() => tester
          .widget<GrowthChart>(find.byKey(const Key('home_growth_chart')));
      expect(chart().unit, 'kg');
      expect(chart().metricLabel, 'Weight');
      expect(chart().compact, isTrue);
    });

    testWidgets('tap opens Growth on the selected measure', (tester) async {
      putHome();
      await showCard(tester, const Variant('en', Brightness.light, 1.0));
      await tester.tap(find.byKey(const Key('home_growth_height')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open growth'));
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.growth), findsOneWidget);
      expect(Get.arguments, GrowthMetric.height);
    });

    testWidgets('no measurements: a prompt, no chart', (tester) async {
      putHome(items: <MeasurementModel>[]);
      await showCard(tester, const Variant('ar', Brightness.dark, 1.3));
      expect(find.byKey(const Key('home_growth_none')), findsOneWidget);
      expect(find.byKey(const Key('home_growth_chart')), findsNothing);
      expectNoOverflow(tester);
    });

    testWidgets('no change reads "No change since"', (tester) async {
      putHome(items: <MeasurementModel>[
        MeasurementModel(id: 'a', date: DateTime(2027, 2, 1), weightKg: 4),
        MeasurementModel(id: 'b', date: DateTime(2027, 3, 1), weightKg: 4),
      ]);
      await showCard(tester, const Variant('en', Brightness.light, 1.0));
      expect(find.text('No change since Feb 1, 2027'), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      putHome();
      await showCard(tester, const Variant('ar', Brightness.dark, 1.3));
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
