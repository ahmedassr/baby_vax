import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/growth/widgets/growth_chart.dart';
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

  group('unusual values (WHO 0.1st / 99.9th percentile)', () {
    test('33 kg at birth is far above; 3.2 kg is not', () {
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight,
              sex: 'female',
              ageMonths: 0,
              value: 33),
          UnusualValue.high);
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight,
              sex: 'female',
              ageMonths: 0,
              value: 3.2),
          UnusualValue.none);
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.height,
              sex: 'male',
              ageMonths: 6,
              value: 25),
          UnusualValue.low);
    });

    test('without the sex, only outside both sexes counts', () {
      // Between the girls' and the boys' 99.9th at birth would be a false
      // question for one of them, so it is not asked.
      final double girlsTop = GrowthReference.valueAt(
          GrowthReference.zFromPercentile(99.9),
          GrowthReference.lmsAt(GrowthMetric.weight, 'female', 0)!);
      final double boysTop = GrowthReference.valueAt(
          GrowthReference.zFromPercentile(99.9),
          GrowthReference.lmsAt(GrowthMetric.weight, 'male', 0)!);
      expect(boysTop, greaterThan(girlsTop));
      final double between = (girlsTop + boysTop) / 2;
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight,
              sex: 'female',
              ageMonths: 0,
              value: between),
          UnusualValue.high);
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight,
              sex: null,
              ageMonths: 0,
              value: between),
          UnusualValue.none);
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight, sex: null, ageMonths: 0, value: 33),
          UnusualValue.high);
    });

    test('over 5 years nothing can be said', () {
      expect(
          GrowthReference.unusual(
              metric: GrowthMetric.weight,
              sex: 'female',
              ageMonths: 70,
              value: 99),
          isNull);
    });

    testWidgets('the question names the value and the unit', (tester) async {
      await pumpApp(tester, const SizedBox());
      final String? m = MeasurementSheet.unusualMessage(
        values: <GrowthMetric, double?>{GrowthMetric.weight: 33},
        date: DateTime(2027, 1, 16),
        birthDate: DateTime(2027, 1, 15),
        sex: 'female',
      );
      expect(m, contains('33 kg'));
      expect(m, contains('far above'));
      expect(
          MeasurementSheet.unusualMessage(
            values: <GrowthMetric, double?>{GrowthMetric.weight: 3.4},
            date: DateTime(2027, 1, 16),
            birthDate: DateTime(2027, 1, 15),
            sex: 'female',
          ),
          isNull);
      expect(
          MeasurementSheet.unusualMessage(
            values: <GrowthMetric, double?>{GrowthMetric.weight: 33},
            date: DateTime(2027, 1, 16),
            birthDate: null,
            sex: 'female',
          ),
          isNull);
    });
  });

  group('plain-language position', () {
    test('bands', () {
      expect(GrowthPosition.of(1), GrowthPosition.belowMost);
      expect(GrowthPosition.of(10), GrowthPosition.belowAverage);
      expect(GrowthPosition.of(50), GrowthPosition.aroundAverage);
      expect(GrowthPosition.of(80), GrowthPosition.aboveAverage);
      expect(GrowthPosition.of(99), GrowthPosition.aboveMost);
    });

    testWidgets('never diagnosis words', (tester) async {
      await pumpApp(tester, const SizedBox());
      for (final GrowthPosition p in GrowthPosition.values) {
        for (final String lang in <String>['en', 'ar']) {
          Get.locale = Locale(lang);
          final String t = 'Growth_position_${p.name}'.tr;
          expect(t, isNot(contains('Growth_')));
          expect(t.toLowerCase(),
              isNot(matches(RegExp('normal|abnormal|risk|obes|underweight'))));
        }
      }
    });
  });

  group('GrowthScale', () {
    test('a 33 kg typo does not stretch the axis; it sits at the edge', () {
      final GrowthScale s = GrowthScale.of(
        metric: GrowthMetric.weight,
        sex: 'female',
        points: const <GrowthPoint>[
          GrowthPoint(age: 0, value: 33),
          GrowthPoint(age: 1.8, value: 4.8),
        ],
        ageNow: 1.8,
      );
      expect(s.band, isNotNull);
      expect(s.yHi, lessThan(12));
      expect(s.isOutside(33), isTrue);
      expect(s.isOutside(4.8), isFalse);
      expect(s.clampY(33), s.yHi);
    });

    test('fitted to the band for the ages shown', () {
      final GrowthScale s = GrowthScale.of(
        metric: GrowthMetric.weight,
        sex: 'male',
        points: const <GrowthPoint>[GrowthPoint(age: 2, value: 5.6)],
        ageNow: 2,
      );
      final double top = s.band!.upper
          .map((p) => p.value)
          .reduce((double a, double b) => a > b ? a : b);
      final double bottom = s.band!.lower
          .map((p) => p.value)
          .reduce((double a, double b) => a < b ? a : b);
      expect(s.yHi, greaterThanOrEqualTo(top));
      expect(s.yLo, lessThanOrEqualTo(bottom));
      expect(s.yHi - top, lessThan(1));
    });

    test('without the sex: no band, still no squashing', () {
      final GrowthScale s = GrowthScale.of(
        metric: GrowthMetric.weight,
        sex: null,
        points: const <GrowthPoint>[
          GrowthPoint(age: 0, value: 33),
          GrowthPoint(age: 1, value: 4),
          GrowthPoint(age: 2, value: 5),
        ],
      );
      expect(s.band, isNull);
      expect(s.yHi, lessThan(6));
      expect(s.isOutside(33), isTrue);
    });
  });

  group('GrowthChart', () {
    final List<GrowthPoint> pts = <GrowthPoint>[
      GrowthPoint(age: 0, value: 3.2, date: DateTime(2027, 1, 15)),
      GrowthPoint(age: 1.8, value: 5.0, date: DateTime(2027, 3, 10)),
    ];

    Widget chart(List<GrowthPoint> points,
            {String? sex = 'female', bool arabic = false}) =>
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GrowthChart(
              key: const Key('chart'),
              metric: GrowthMetric.weight,
              points: points,
              sex: sex,
              unit: arabic ? 'كغ' : 'kg',
              metricLabel: arabic ? 'الوزن' : 'Weight',
              semanticLabel: 'chart',
              ageNow: 1.8,
            ),
          ),
        );

    for (final Variant v in mainVariants) {
      testWidgets('age runs left to right; legend; fits ($v)', (tester) async {
        await pumpApp(tester, chart(pts, arabic: v.rtl), variant: v);
        final GrowthChartState st =
            tester.state<GrowthChartState>(find.byKey(const Key('chart')));
        final List<Offset> o = st.pointOffsets;
        expect(o[0].dx, lessThan(o[1].dx), reason: 'not mirrored in $v');
        expect(find.byKey(const Key('growth_legend_band')), findsOneWidget);
        expect(find.byKey(const Key('growth_legend_average')), findsOneWidget);
        expect(find.byKey(const Key('growth_legend_baby')), findsOneWidget);
        expect(find.byKey(const Key('growth_band_caption')), findsOneWidget);
        expect(find.textContaining('percentile'), findsNothing);
        expectNoOverflow(tester);
      });
    }

    Future<void> tapPoint(WidgetTester tester, int i) async {
      final GrowthChartState st =
          tester.state<GrowthChartState>(find.byKey(const Key('chart')));
      final Offset origin =
          tester.getTopLeft(find.byKey(const Key('growth_chart_tap')));
      await tester.tapAt(origin + st.pointOffsets[i]);
      await tester.pumpAndSettle();
    }

    testWidgets('tap a point: date, age, value, plain position',
        (tester) async {
      await pumpApp(tester, chart(pts));
      await tapPoint(tester, 1);
      expect(find.byKey(const Key('growth_point_details')), findsOneWidget);
      expect(find.text('5 kg'), findsOneWidget);
      expect(find.textContaining('Mar 10, 2027'), findsOneWidget);
      final Text pos =
          tester.widget<Text>(find.byKey(const Key('growth_point_position')));
      expect(
          pos.data,
          anyOf('Around average', 'A little below average',
              'A little above average'));
      // Tapping it again closes it.
      await tapPoint(tester, 1);
      expect(find.byKey(const Key('growth_point_details')), findsNothing);
    });

    testWidgets('Arabic RTL dark x1.3: tap details fit', (tester) async {
      await pumpApp(tester, chart(pts, arabic: true),
          variant: const Variant('ar', Brightness.dark, 1.3));
      await tapPoint(tester, 0);
      expect(find.byKey(const Key('growth_point_details')), findsOneWidget);
      expect(find.text('3.2 كغ'), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('an outlier is drawn at the top edge and explained',
        (tester) async {
      await pumpApp(
          tester,
          chart(<GrowthPoint>[
            GrowthPoint(age: 0, value: 33, date: DateTime(2027, 1, 15)),
            pts[1],
          ]));
      final GrowthChartState st =
          tester.state<GrowthChartState>(find.byKey(const Key('chart')));
      expect(st.scale!.isOutside(33), isTrue);
      expect(find.byKey(const Key('growth_legend_outside')), findsOneWidget);
      await tapPoint(tester, 0);
      expect(find.text('33 kg'), findsOneWidget);
      expect(find.text("Growth_point_outside".tr), findsOneWidget);
    });

    testWidgets('without the sex: only "Your baby" in the legend',
        (tester) async {
      await pumpApp(tester, chart(pts, sex: null));
      expect(find.byKey(const Key('growth_legend_band')), findsNothing);
      expect(find.byKey(const Key('growth_legend_baby')), findsOneWidget);
      expect(find.byKey(const Key('growth_band_caption')), findsNothing);
    });
  });

  group('GrowthView empty states', () {
    GrowthController put(List<MeasurementModel> items) {
      final c = GrowthController(
        load: (_) async => items,
        save: (_, m) async => WriteOutcome.synced,
        delete: (_, __) async {},
        updateProfile: (_, __) async {},
        user: () => sampleUser(),
        clock: () => fixedNow,
      );
      Get.put<GrowthController>(c);
      return c;
    }

    for (final Variant v in mainVariants) {
      testWidgets('one measurement: chart and a hint ($v)', (tester) async {
        put(<MeasurementModel>[
          MeasurementModel(id: 'a', date: DateTime(2027, 2, 1), weightKg: 4),
        ]);
        await pumpApp(tester, const GrowthView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('growth_chart')), findsOneWidget);
        expect(find.byKey(const Key('growth_chart_one')), findsOneWidget);
        expectNoOverflow(tester);
      });

      testWidgets('none of this measure: a message, no chart ($v)',
          (tester) async {
        final c = put(<MeasurementModel>[
          MeasurementModel(id: 'a', date: DateTime(2027, 2, 1), weightKg: 4),
        ]);
        await pumpApp(tester, const GrowthView(), variant: v);
        await tester.pumpAndSettle();
        c.setMetric(GrowthMetric.head);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('growth_chart')), findsNothing);
        expect(find.byKey(const Key('growth_chart_empty')), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('opens on the measure Home asked for', (tester) async {
      await pumpApp(tester, const Scaffold());
      Get.routing.args = GrowthMetric.height;
      final c = put(const <MeasurementModel>[]);
      expect(c.metric.value, GrowthMetric.height);
    });
  });

  group('MeasurementSheet asks before saving an unusual value', () {
    Future<(List<MeasurementSheetResult?>, List<String>)> open(
        WidgetTester tester,
        {required bool answer,
        Variant variant = const Variant('en', Brightness.light, 1.0)}) async {
      final List<MeasurementSheetResult?> out = <MeasurementSheetResult?>[];
      final List<String> asked = <String>[];
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  out.add(await AppSheet.show(MeasurementSheet(
                today: DateTime(2027, 1, 16),
                birthDate: DateTime(2027, 1, 15),
                sex: 'female',
                confirmUnusual: (String m) async {
                  asked.add(m);
                  return answer;
                },
              ))),
              child: const Text('open'),
            ),
          ),
        ),
        variant: variant,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (out, asked);
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('growth_save')));
      await tester.tap(find.byKey(const Key('growth_save')));
      await tester.pumpAndSettle();
    }

    testWidgets('"Check again" keeps the sheet open', (tester) async {
      final (out, asked) = await open(tester, answer: false);
      await tester.enterText(field('growth_weight'), '33');
      await save(tester);
      expect(asked.single, contains('33 kg'));
      expect(out, isEmpty);
      expect(find.byType(MeasurementSheet), findsOneWidget);
    });

    testWidgets('"Save anyway" saves it', (tester) async {
      final (out, asked) = await open(tester, answer: true);
      await tester.enterText(field('growth_weight'), '33');
      await save(tester);
      expect(asked, hasLength(1));
      expect((out.single as SaveMeasurement).measurement.weightKg, 33);
    });

    testWidgets('a usual value is saved without a question', (tester) async {
      final (out, asked) = await open(tester, answer: false);
      await tester.enterText(field('growth_weight'), '3.4');
      await save(tester);
      expect(asked, isEmpty);
      expect((out.single as SaveMeasurement).measurement.weightKg, 3.4);
    });

    testWidgets('Arabic question uses Western digits', (tester) async {
      final (_, asked) = await open(tester,
          answer: false, variant: const Variant('ar', Brightness.dark, 1.3));
      await tester.enterText(field('growth_weight'), '33');
      await save(tester);
      expect(asked.single, contains('33 كغ'));
      expect(RegExp('[٠-٩]').hasMatch(asked.single), isFalse);
      expectNoOverflow(tester);
    });
  });
}
