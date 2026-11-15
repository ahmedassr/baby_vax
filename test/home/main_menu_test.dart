import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
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

  void putAll() {
    Get.put<HomeController>(HomeController(
      notificationsEnabled: () async => true,
      loadUser: (_) async => sampleUser(),
      loadDoses: (_) async => sampleSchedule(),
      clock: () => fixedNow,
    ));
    Get.put<MedicalDatesController>(MedicalDatesController(
      loadDoses: (_) async => sampleSchedule(),
      birthday: () => DateTime(2027, 1, 15),
      clock: () => fixedNow,
    ));
    Get.put<TipsController>(TipsController(load: (_) async => <TipsModel>[]));
    Get.put<GrowthController>(GrowthController(
      load: (_) async => <MeasurementModel>[
        MeasurementModel(id: 'm1', date: DateTime(2027, 3, 1), weightKg: 4.6),
      ],
      user: () => sampleUser(),
      clock: () => fixedNow,
    ));
    Get.put<SettingsController>(SettingsController(
      write: (_, __) async {},
      remove: (_) {},
      notificationsEnabled: () async => true,
    ));
    Get.put<MainMenuController>(MainMenuController());
  }

  for (final Variant v in mainVariants) {
    testWidgets('every tab renders with labelled navigation ($v)',
        (tester) async {
      putAll();
      await pumpApp(tester, const MainMenuView(), variant: v);
      await tester.pumpAndSettle();
      for (int i = 0; i < 4; i++) {
        final MainMenuController c = Get.find<MainMenuController>();
        await tester.tap(find.text(c.item[i].title.tr).last);
        await tester.pumpAndSettle();
        expect(c.currentIndex.value, i);
        expectNoOverflow(tester);
      }
    });
  }

  testWidgets('tabs: Home, Schedule, Growth, Settings — no Tips tab',
      (tester) async {
    putAll();
    await pumpApp(tester, const MainMenuView());
    await tester.pumpAndSettle();
    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.destinations.map((d) => (d as NavigationDestination).label),
        <String>['Home', 'Schedule', 'Growth', 'Settings']);
    expect(find.text('Tips'), findsNothing);

    // Growth as a tab: the shell's bar is the only app bar, and the tab
    // keeps its FAB (there are measurements).
    await tester.tap(find.text('Growth').last);
    await tester.pumpAndSettle();
    expect(Get.find<MainMenuController>().currentIndex.value,
        MainMenuController.growthTab);
    expect(find.byType(GrowthView), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const Key('growth_add')), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('Home opens Growth by switching to its tab', (tester) async {
    putAll();
    await pumpApp(tester, const MainMenuView());
    await tester.pumpAndSettle();
    Get.find<HomeController>().openGrowth();
    await tester.pumpAndSettle();
    expect(Get.find<MainMenuController>().currentIndex.value,
        MainMenuController.growthTab);
    expect(routeStub(AppRoutes.growth), findsNothing);
  });

  testWidgets('navigation labels are always visible', (tester) async {
    putAll();
    await pumpApp(tester, const MainMenuView());
    await tester.pumpAndSettle();
    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(4));
    expect(
        Theme.of(tester.element(find.byType(NavigationBar)))
            .navigationBarTheme
            .labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow);
  });

  testWidgets('tap targets and labels on the shell', (tester) async {
    final handle = tester.ensureSemantics();
    putAll();
    await pumpApp(tester, const MainMenuView());
    await tester.pumpAndSettle();
    await expectTapTargets(tester);
    await expectLabelledTargets(tester);
    handle.dispose();
  });
}
