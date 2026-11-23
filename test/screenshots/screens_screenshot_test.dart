// Renders the main screens to PNG files for the PR description (before and
// after a visual change), in light and dark, English and Arabic.
//
// Skipped unless SCREENSHOTS_DIR is set, so the normal test run never writes
// files:
//
//   SCREENSHOTS_DIR=build/screenshots/after \
//     flutter test test/screenshots/screens_screenshot_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/medical_date_details/view/medical_date_details_view.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/tips/controller/tips_controller.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';
import '../service/vaccine_state_service_test.dart'
    show FakeReminders, FakeWriter;

final String? outDir = Platform.environment['SCREENSHOTS_DIR'];

const List<Variant> shotVariants = <Variant>[
  Variant('en', Brightness.light, 1.0),
  Variant('en', Brightness.dark, 1.0),
  Variant('ar', Brightness.light, 1.0),
  Variant('ar', Brightness.dark, 1.0),
];

/// Material Icons from the Flutter SDK, so icons are drawn instead of boxes.
Future<void> loadIconFont() async {
  final String root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final File f = File('$root/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (!f.existsSync()) return;
  final Uint8List bytes = f.readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}

Future<void> shoot(WidgetTester tester, String name, Variant v) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
      find.byType(RepaintBoundary).first) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2);
    final ByteData? png =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final File file = File(
        '$outDir/${name}_${v.locale}_${v.brightness.name}.png')
      ..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await loadIconFont();
  });
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  final bool skip = outDir == null;

  List<HealthEntry> health() => <HealthEntry>[
        HealthEntry(
            id: 't1',
            kind: HealthEntryKind.temperature,
            at: fixedNow.subtract(const Duration(hours: 26)),
            tempC: 37.0,
            method: TemperatureMethod.armpit),
        HealthEntry(
            id: 't2',
            kind: HealthEntryKind.temperature,
            at: fixedNow.subtract(const Duration(hours: 2)),
            tempC: 37.4,
            method: TemperatureMethod.armpit),
        HealthEntry(
            id: 'm1',
            kind: HealthEntryKind.medicine,
            at: fixedNow.subtract(const Duration(hours: 3)),
            medicine: 'Paracetamol',
            amount: '2.5 ml'),
      ];

  void putTabs() {
    Get.put<HomeController>(HomeController(
      notificationsEnabled: () async => true,
      loadUser: (_) async => sampleUser(),
      loadDoses: (_) async => sampleSchedule(),
      loadMeasurements: (_) async => <MeasurementModel>[
        MeasurementModel(
            id: 'm1', date: DateTime(2027, 3, 10), weightKg: 5.0, heightCm: 57)
      ],
      clock: () => fixedNow,
    ));
    Get.put<MedicalDatesController>(MedicalDatesController(
      loadDoses: (_) async => sampleSchedule(),
      birthday: () => DateTime(2027, 1, 15),
      clock: () => fixedNow,
    ));
    Get.put<TipsController>(TipsController(load: (_) async => <TipsModel>[]));
    Get.put<HealthController>(HealthController(
      load: (_) async => health(),
      save: (_, e) async => ('x', WriteOutcome.synced),
      delete: (_, __) async {},
      user: () => sampleUser(),
      doses: () => sampleSchedule(),
      clock: () => fixedNow,
    ));
    Get.put<SettingsController>(SettingsController(
      write: (_, __) async {},
      remove: (_) {},
      notificationsEnabled: () async => true,
    ));
    Get.put<MainMenuController>(MainMenuController());
  }

  for (final Variant v in shotVariants) {
    testWidgets('tabs $v', skip: skip, (tester) async {
      putTabs();
      await pumpApp(tester, const RepaintBoundary(child: MainMenuView()),
          variant: v, size: const Size(360, 760));
      await tester.pumpAndSettle();
      const List<String> names = <String>[
        'home',
        'schedule',
        'health',
        'settings'
      ];
      final MainMenuController c = Get.find<MainMenuController>();
      for (int i = 0; i < c.item.length && i < names.length; i++) {
        await tester.tap(find.text(c.item[i].title.tr).last);
        await tester.pumpAndSettle();
        await shoot(tester, names[i], v);
      }
    });

    testWidgets('dose details $v', skip: skip, (tester) async {
      Get.put<MedicalDateDetailsController>(MedicalDateDetailsController(
        dose: sampleSchedule()[1],
        stateService: VaccineStateService(
            writer: FakeWriter(), reminders: FakeReminders()),
        confirm: (_) async => true,
        recordSheet: (_, {required bool editing}) async => null,
        clock: () => fixedNow,
      ));
      await pumpApp(
          tester, const RepaintBoundary(child: MedicalDateDetailsView()),
          variant: v, size: const Size(360, 760));
      await tester.pumpAndSettle();
      await shoot(tester, 'dose_details', v);
    });

    testWidgets('growth $v', skip: skip, (tester) async {
      final List<MeasurementModel> m = <MeasurementModel>[
        MeasurementModel(
            id: 'm1',
            date: DateTime(2027, 1, 15),
            weightKg: 3.2,
            heightCm: 49.1),
        MeasurementModel(
            id: 'm2', date: DateTime(2027, 2, 15), weightKg: 4.1),
        MeasurementModel(
            id: 'm3', date: DateTime(2027, 3, 10), weightKg: 5.0, headCm: 38.3),
      ];
      Get.put<GrowthController>(GrowthController(
        load: (_) async => m,
        save: (_, x) async => WriteOutcome.synced,
        delete: (_, __) async {},
        updateProfile: (_, __) async {},
        user: () => sampleUser(),
        clock: () => fixedNow,
      ));
      await pumpApp(tester, const RepaintBoundary(child: GrowthView()),
          variant: v, size: const Size(360, 760));
      await tester.pumpAndSettle();
      await shoot(tester, 'growth', v);
    });

    testWidgets('sign-up $v', skip: skip, (tester) async {
      Get.put<SignupController>(SignupController(
        clock: () => fixedNow,
        createAccount: (_, __) async => 'uid',
        saveProfile: (_, __) async {},
        rollbackAccount: () async {},
        onCreated: (_) async {},
        requestPermission: () async => true,
      ));
      await pumpApp(tester, const RepaintBoundary(child: SignupView()),
          variant: v, size: const Size(360, 760));
      await tester.pumpAndSettle();
      await shoot(tester, 'signup', v);
    });
  }
}
