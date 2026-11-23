// Phone review R5b: Home shows a tip of the day (rotating daily, offline
// from the loaded tips) with "See all tips"; the tips list is its own
// screen, also reached from Settings. Growth stays a quick action.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/home/view/home_view.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:baby_vax/app/modules/tips/model/tip_of_the_day.dart';
import 'package:baby_vax/app/modules/tips/view/tips_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  final List<TipsModel> tips = <TipsModel>[
    TipsModel(id: 'a', title: 'Safe sleep', description: 'On the back.'),
    TipsModel(id: 'b', title: 'Bath time', description: 'Short and warm.'),
    TipsModel(
        id: 'c',
        title: 'تغذية الرضيع في الأشهر الستة الأولى',
        description: 'الرضاعة الطبيعية وحدها تكفي طفلك. ' * 4),
  ];

  group('TipOfTheDay', () {
    test('the same tip all day, the next one tomorrow', () {
      final TipsModel morning =
          TipOfTheDay.pick(tips, DateTime(2027, 3, 10, 0, 5))!;
      final TipsModel night =
          TipOfTheDay.pick(tips, DateTime(2027, 3, 10, 23, 55))!;
      final TipsModel tomorrow =
          TipOfTheDay.pick(tips, DateTime(2027, 3, 11, 8))!;
      expect(night.id, morning.id);
      expect(tomorrow.id, isNot(morning.id));
    });

    test('cycles through every tip', () {
      final Set<String?> seen = <String?>{
        for (int d = 0; d < tips.length; d++)
          TipOfTheDay.pick(tips, DateTime(2027, 3, 10 + d))!.id,
      };
      expect(seen, hasLength(tips.length));
    });

    test('the order tips arrive in does not change the pick', () {
      final DateTime day = DateTime(2027, 3, 10);
      expect(TipOfTheDay.pick(tips.reversed.toList(), day)!.id,
          TipOfTheDay.pick(tips, day)!.id);
    });

    test('no tips, no pick', () {
      expect(TipOfTheDay.pick(<TipsModel>[], DateTime(2027)), isNull);
    });
  });

  late int loads;
  late bool offline;

  void putAll() {
    loads = 0;
    offline = false;
    Get.put<HomeController>(HomeController(
      notificationsEnabled: () async => true,
      loadUser: (_) async => sampleUser(),
      loadDoses: (_) async => sampleSchedule(),
      clock: () => fixedNow,
    ));
    Get.put<TipsController>(TipsController(load: (_) async {
      loads++;
      if (offline) throw Exception('unavailable');
      return tips;
    }));
  }

  Finder tipCard() => find.byKey(const Key('home_tip_of_day'));

  Future<void> scrollToTip(WidgetTester tester) async {
    await tester.scrollUntilVisible(tipCard(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tipCard());
    await tester.pumpAndSettle();
  }

  for (final Variant v in mainVariants) {
    testWidgets(
        'Home: tip of the day with See all tips'
        '($v)', (tester) async {
      putAll();
      await pumpApp(tester, const Scaffold(body: HomeView()), variant: v);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_action_growth')), findsOneWidget);
      expect(find.byKey(const Key('home_action_card')), findsOneWidget);
      expect(find.byKey(const Key('home_action_reminders')), findsOneWidget);
      await scrollToTip(tester);
      final TipsModel today = TipOfTheDay.pick(tips, fixedNow)!;
      expect(
          find.descendant(
              of: tipCard(),
              matching: find.textContaining(today.title.substring(0, 5))),
          findsOneWidget);
      expect(find.text("Home_tip_of_day".tr), findsOneWidget);
      expect(find.text("Home_see_all_tips".tr), findsOneWidget);
      expectNoOverflow(tester);
    });
  }

  testWidgets('tapping the tip opens its details; See all opens the list',
      (tester) async {
    putAll();
    await pumpApp(tester, const Scaffold(body: HomeView()));
    await tester.pumpAndSettle();
    await scrollToTip(tester);
    await tester.tap(tipCard());
    await tester.pumpAndSettle();
    expect(routeStub(AppRoutes.tipDetails), findsOneWidget);
    expect(
        AppConstant.argumentService.getArguments<InternalScreenArgs>()?.tip?.id,
        TipOfTheDay.pick(tips, fixedNow)!.id);
    Get.back<void>();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Home_see_all_tips".tr));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Home_see_all_tips".tr));
    await tester.pumpAndSettle();
    expect(routeStub(AppRoutes.tips), findsOneWidget);
  });

  testWidgets('offline: a failed refresh keeps today\'s tip', (tester) async {
    putAll();
    await pumpApp(tester, const Scaffold(body: HomeView()));
    await tester.pumpAndSettle();
    await scrollToTip(tester);
    expect(tipCard(), findsOneWidget);
    offline = true;
    await Get.find<TipsController>().fetchTips();
    await tester.pumpAndSettle();
    expect(loads, greaterThan(1));
    expect(tipCard(), findsOneWidget);
  });

  testWidgets('no tips: no card, Home still complete', (tester) async {
    putAll();
    Get.delete<TipsController>();
    Get.put<TipsController>(TipsController(load: (_) async => <TipsModel>[]));
    await pumpApp(tester, const Scaffold(body: HomeView()));
    await tester.pumpAndSettle();
    expect(tipCard(), findsNothing);
    expect(find.text("Home_tip_of_day".tr), findsNothing);
    expectNoOverflow(tester);
  });

  for (final Variant v in mainVariants) {
    testWidgets('the tips list is its own screen with a title ($v)',
        (tester) async {
      putAll();
      await pumpApp(tester, const TipsScreen(), variant: v);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, "MainMenuController_tips_title".tr),
          findsOneWidget);
      expect(find.textContaining('Bath time'), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}
