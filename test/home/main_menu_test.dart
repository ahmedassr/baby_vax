import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
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
