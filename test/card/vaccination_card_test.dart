import 'dart:io';
import 'dart:typed_data';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccination_card/vaccination_card_data.dart';
import 'package:baby_vax/app/core/service/vaccination_card/vaccination_card_pdf.dart';
import 'package:baby_vax/app/core/service/vaccination_card/vaccination_card_service.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/vaccination_card/vaccination_card_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

/// The bundled Cairo, read from disk so the test needs no asset bundle.
pw.Font cairo() => pw.Font.ttf(ByteData.sublistView(
    File(VaccinationCardService.fontAsset).readAsBytesSync()));

void main() {
  tearDown(Get.reset);

  List<MedicalDatesModel> doses() {
    final List<MedicalDatesModel> s = sampleSchedule(states: <String, String>{
      'bcg_hepb_birth': 'Completed',
      'penta_opv_pcv_1': 'Skipped',
    });
    s[0] = s[0].copyWith(
        record: DoseRecord(
            givenDate: DateTime(2027, 1, 16),
            clinic: 'عيادة رام الله',
            lot: 'AB1234'));
    // A record left on a pending dose by a v1.0 undo.
    s[2] = s[2].copyWith(record: const DoseRecord(clinic: 'stale'));
    return s.reversed.toList();
  }

  group('VaccinationCardData', () {
    late VaccinationCardData data;
    setUp(() => data = VaccinationCardData.build(
        user: sampleUser(), doses: doses(), now: fixedNow));

    test('every dose, in date order, with names in both languages', () {
      expect(data.rows, hasLength(10));
      expect(data.rows.first.vaccine.en, 'BCG and Hepatitis B (1st dose)');
      expect(data.rows.first.vaccine.ar,
          'لقاح السل والتهاب الكبد ب (الجرعة الأولى)');
    });

    test('status in both languages, including "قيد الانتظار"', () {
      expect(data.rows[0].status.en, 'Completed');
      expect(data.rows[1].status.en, 'Skipped');
      expect(data.rows[2].status.ar, 'قيد الانتظار');
    });

    test('record fields on a given dose; none on others', () {
      expect(data.rows[0].given, '16/01/2027');
      expect(data.rows[0].clinic, 'عيادة رام الله');
      expect(data.rows[0].lot, 'AB1234');
      expect(data.rows[2].clinic, isNull, reason: 'stale v1.0 record');
    });

    test('dates are dd/MM/yyyy with Western digits', () {
      expect(data.rows[0].scheduled, '15/01/2027');
      expect(data.birthDate, '15/01/2027');
      expect(data.generatedOn, '10/03/2027');
      for (final r in data.rows) {
        expect(RegExp('[٠-٩]').hasMatch(r.scheduled), isFalse);
      }
    });

    test('baby details and a safe file name', () {
      expect(data.childName, 'Lina');
      expect(data.sex!.en, 'Girl');
      expect(data.sex!.ar, 'بنت');
      expect(data.fileName, 'baby-vax-vaccination-card-lina.pdf');
      final arabic = VaccinationCardData.build(
          user: sampleUser()..uid = 'x',
          doses: const <MedicalDatesModel>[],
          now: fixedNow);
      expect(arabic.fileName, endsWith('.pdf'));
    });

    test('a profile without sex or birth date still builds', () {
      final d = VaccinationCardData.build(
          user: UserModel(uid: 'u', email: 'e'), doses: doses(), now: fixedNow);
      expect(d.sex, isNull);
      expect(d.birthDate, isNull);
    });
  });

  test('builds a real PDF with Arabic and English, offline', () async {
    final data = VaccinationCardData.build(
        user: sampleUser(), doses: doses(), now: fixedNow);
    final Uint8List bytes = await VaccinationCardPdf.build(data, font: cairo());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000), reason: 'font is embedded');
  });

  group('VaccinationCardSheet', () {
    late List<String> shared;
    late List<String> printed;

    void put({bool fail = false}) {
      shared = <String>[];
      printed = <String>[];
      SessionManager.authUid = () => 'alice';
      final home = HomeController(
        notificationsEnabled: () async => true,
        loadUser: (_) async => sampleUser(),
        loadDoses: (_) async => doses(),
        clock: () => fixedNow,
      );
      Get.put<HomeController>(home);
      Get.put<VaccinationCardService>(VaccinationCardService(
        loadFont: () async => cairo(),
        clock: () => fixedNow,
        share: (b, name) async {
          if (fail) throw Exception('no share target');
          shared.add(name);
        },
        print: (b, name) async => printed.add(name),
      ));
    }

    tearDown(() => SessionManager.authUid = () => null);

    for (final Variant v in mainVariants) {
      testWidgets('fits and shares ($v)', (tester) async {
        put();
        await pumpApp(
            tester,
            Scaffold(
                body: VaccinationCardSheet(
                    service: Get.find<VaccinationCardService>())),
            variant: v);
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
        await tester.tap(find.byKey(const Key('card_share')));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 500)));
        await tester.pumpAndSettle();
        expect(shared, <String>['baby-vax-vaccination-card-lina.pdf']);
      });
    }

    testWidgets('print goes to the print sheet', (tester) async {
      put();
      await pumpApp(
          tester,
          Scaffold(
              body: VaccinationCardSheet(
                  service: Get.find<VaccinationCardService>())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card_print')));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();
      expect(printed, hasLength(1));
    });

    testWidgets('a failure shows a banner', (tester) async {
      put(fail: true);
      await pumpApp(
          tester,
          Scaffold(
              body: VaccinationCardSheet(
                  service: Get.find<VaccinationCardService>())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card_share')));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('card_error')), findsOneWidget);
    });
  });
}
