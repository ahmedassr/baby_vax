import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/service/phone_dialer.dart';
import 'package:baby_vax/app/modules/health/controller/health_controller.dart';
import 'package:baby_vax/app/modules/health/model/health_entry.dart';
import 'package:baby_vax/app/modules/health/view/health_guide_view.dart';
import 'package:baby_vax/app/modules/health/view/health_view.dart';
import 'package:baby_vax/app/modules/health/widgets/health_entry_sheet.dart';
import 'package:baby_vax/app/modules/health/widgets/health_labels.dart';
import 'package:flutter/services.dart';
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

  // sampleUser is born 15 Jan 2027: on fixedNow (10 Mar 2027, noon) a
  // young infant, so a 37.6 °C armpit reading is a WHO danger sign.
  List<HealthEntry> sample() => <HealthEntry>[
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
            tempC: 37.6,
            method: TemperatureMethod.armpit,
            note: 'After the bath'),
        HealthEntry(
            id: 's1',
            kind: HealthEntryKind.symptoms,
            at: fixedNow.subtract(const Duration(hours: 3)),
            symptoms: const <HealthSymptom>[
              HealthSymptom.injectionSite,
              HealthSymptom.crying
            ]),
        HealthEntry(
            id: 'm1',
            kind: HealthEntryKind.medicine,
            at: fixedNow.subtract(const Duration(hours: 3)),
            medicine: 'Paracetamol',
            amount: '2.5 ml'),
        HealthEntry(
            id: 'n1',
            kind: HealthEntryKind.note,
            at: fixedNow.subtract(const Duration(hours: 30)),
            note: 'Slept well'),
      ];

  /// The schedule with the 2-month doses given yesterday.
  List<MedicalDatesModel> givenYesterday() {
    final List<MedicalDatesModel> s = sampleSchedule();
    s[1] = s[1].copyWith(
        state: 'Completed',
        record: DoseRecord(givenDate: DateTime(2027, 3, 9)));
    return s;
  }

  late FakeHealthStore store;

  HealthController put(
      {List<HealthEntry>? entries,
      List<MedicalDatesModel>? doses,
      UserModel? user}) {
    store = FakeHealthStore(entries ?? sample());
    final HealthController c =
        store.controller(doses: doses ?? givenYesterday(), user: user);
    Get.put<HealthController>(c);
    return c;
  }

  Future<void> pump(WidgetTester tester, {Variant? variant}) async {
    await pumpApp(tester, const Scaffold(body: HealthView()),
        variant: variant ?? const Variant('en', Brightness.light, 1.0));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }

  for (final Variant v in mainVariants) {
    testWidgets('the whole tab fits ($v)', (tester) async {
      put(
          user: sampleUser().withHealth(
              allergies: 'Penicillin',
              conditions: null,
              bloodType: 'O+',
              emergencyContact: const EmergencyContact(
                  name: 'Mum', phone: '0599000000', relation: 'mother')));
      await pump(tester, variant: v);
      expect(find.byKey(const Key('health_after_vaccine')), findsOneWidget);
      expect(find.byKey(const Key('health_add_temperature')), findsOneWidget);
      expectNoOverflow(tester);
      for (final String k in <String>[
        'health_chart',
        'health_last_medicine',
        'health_entry_t2',
        'health_profile_Health_blood_type',
        'health_open_guide',
      ]) {
        await scrollTo(tester, find.byKey(Key(k)));
        expectNoOverflow(tester);
      }
      await scrollTo(tester, find.byType(MedicalDisclaimer));
      expectNoOverflow(tester);
    });

    testWidgets('empty: the add tiles are the way in, no FAB ($v)',
        (tester) async {
      put(entries: <HealthEntry>[], doses: sampleSchedule());
      await pump(tester, variant: v);
      expect(find.byKey(const Key('health_after_vaccine')), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      await scrollTo(tester, find.byKey(const Key('health_empty')));
      expect(find.byKey(const Key('health_profile_empty')), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('When to get medical help fits and names WHO ($v)',
        (tester) async {
      await pumpApp(tester, const HealthGuideView(), variant: v);
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
      await scrollTo(tester, find.byKey(const Key('health_guide_source')));
      expect(
          tester
              .widget<Text>(find.byKey(const Key('health_guide_source')))
              .data,
          contains(
              v.rtl ? 'منظمة الصحة العالمية' : 'World Health Organization'));
      expectNoOverflow(tester);
    });
  }

  testWidgets('after the vaccine: day count, WHO wording, linked logging',
      (tester) async {
    put();
    await pump(tester);
    expect(find.text('Day 2 of 3 after the vaccine'), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Day 2 of 3 after the vaccine'),
        findsOneWidget,
        reason: 'the progress bar is read as words');
    expect(find.textContaining('a sore arm or a mild fever'), findsOneWidget);
    await tester.tap(find.byKey(const Key('health_after_temperature')));
    await tester.pumpAndSettle();
    expect(find.byType(HealthEntrySheet), findsOneWidget);
    expect(
        tester.widget<HealthEntrySheet>(find.byType(HealthEntrySheet)).doseId,
        sampleSchedule()[1].id);
  });

  testWidgets('a young infant\'s 37.6 °C is flagged with words, not colour',
      (tester) async {
    put();
    await pump(tester);
    await scrollTo(tester, find.byKey(const Key('health_care_urgent')));
    expect(
        find.descendant(
            of: find.byKey(const Key('health_latest_temp')),
            matching: find.byKey(const Key('health_care_urgent'))),
        findsOneWidget,
        reason: 'on the latest temperature');
    await scrollTo(tester, find.byKey(const Key('health_entry_t2')));
    expect(
        find.descendant(
            of: find.byKey(const Key('health_entry_t2')),
            matching: find.text("Health_flag_urgent".tr)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('health_entry_s1')),
            matching: find.text("Health_flag_urgent".tr)),
        findsNothing);
  });

  testWidgets('quick add: log a temperature and see it in the log',
      (tester) async {
    put(entries: <HealthEntry>[], doses: sampleSchedule());
    await pump(tester);
    await tester.tap(find.byKey(const Key('health_add_temperature')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('health_temp')),
            matching: find.byType(TextField)),
        '36.9');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('health_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_save')));
    await tester.pumpAndSettle();
    expect(store.entries.single.tempC, 36.9);
    expect(find.byKey(const Key('health_latest_temp')), findsOneWidget);
    expect(find.text(HealthLabels.temperature(36.9)), findsOneWidget);
  });

  testWidgets('last medicine says how long ago', (tester) async {
    put();
    await pump(tester);
    await scrollTo(tester, find.byKey(const Key('health_last_medicine')));
    expect(find.textContaining('3 hours ago'), findsOneWidget);
    expect(find.textContaining('Paracetamol'), findsWidgets);
  });

  testWidgets('Arabic: Western digits throughout', (tester) async {
    put();
    await pump(tester, variant: const Variant('ar', Brightness.dark, 1.3));
    final StringBuffer seen = StringBuffer();
    void collect() => seen.write(tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' '));
    for (final String k in <String>[
      'health_latest_temp',
      'health_last_medicine',
      'health_entry_t2',
      'health_entry_n1',
    ]) {
      await scrollTo(tester, find.byKey(Key(k)));
      collect();
    }
    final String all = seen.toString();
    expect(all, contains('37.6 °C'));
    expect(all, contains('منذ ساعتين'), reason: 'the latest reading, 2 h ago');
    expect(RegExp('[٠-٩]').hasMatch(all), isFalse);
  });

  testWidgets('the guide row opens When to get medical help', (tester) async {
    put();
    await pump(tester);
    await scrollTo(tester, find.byKey(const Key('health_open_guide')));
    await tester.tap(find.byKey(const Key('health_open_guide')));
    await tester.pumpAndSettle();
    expect(routeStub(AppRoutes.healthGuide), findsOneWidget);
  });

  group('time ago, with plural forms', () {
    String ago(int minutes, String lang) {
      Get.locale = Locale(lang);
      return HealthView.ago(
          fixedNow.subtract(Duration(minutes: minutes)), fixedNow);
    }

    testWidgets('English and Arabic', (tester) async {
      await pumpApp(tester, const SizedBox());
      expect(ago(0, 'en'), 'Just now');
      expect(ago(1, 'en'), '1 minute ago');
      expect(ago(60, 'en'), '1 hour ago');
      expect(ago(180, 'en'), '3 hours ago');
      expect(ago(60 * 72, 'en'), '3 days ago');
      expect(ago(120, 'ar'), 'منذ ساعتين');
      expect(ago(180, 'ar'), 'منذ 3 ساعات');
      expect(ago(11 * 60, 'ar'), 'منذ 11 ساعة');
      expect(ago(60 * 24 * 2, 'ar'), 'منذ يومين');
      expect(ago(5, 'ar'), 'منذ 5 دقائق');
      Get.locale = const Locale('en');
    });
  });

  testWidgets('tap targets and labels', (tester) async {
    final handle = tester.ensureSemantics();
    put();
    await pump(tester);
    await expectTapTargets(tester);
    await expectLabelledTargets(tester);
    handle.dispose();
  });

  group('medical ID', () {
    const EmergencyContact sara = EmergencyContact(
        name: 'Sara', phone: '+970599000000', relation: 'mother');
    UserModel withContact(EmergencyContact? c) => sampleUser().withHealth(
        allergies: 'Penicillin',
        conditions: null,
        bloodType: 'O+',
        emergencyContact: c);

    for (final Variant v in mainVariants) {
      testWidgets('shows the contact with Call and Copy ($v)', (tester) async {
        put(user: withContact(sara));
        await pump(tester, variant: v);
        await scrollTo(tester, find.byKey(const Key('health_contact_call')));
        expectNoOverflow(tester);
        expectNoBrokenWords(tester,
            within: find.byKey(const Key('health_medical_id')));
        expect(
            find.text(v.rtl ? 'Sara (الأم)' : 'Sara (Mother)',
                findRichText: true),
            findsNothing,
            reason: 'the name is isolated, so match on parts');
        expect(find.textContaining(v.rtl ? 'الأم' : 'Mother'), findsOneWidget);
        final Text phone = tester
            .widget<Text>(find.byKey(const Key('health_contact_phone_text')));
        expect(phone.textDirection, TextDirection.ltr);
        expect(phone.data, contains('+970599000000'));
        expect(
            tester.getSize(find.byKey(const Key('health_contact_copy'))).height,
            greaterThanOrEqualTo(48));
      });
    }

    testWidgets('Call opens the dialer with the number', (tester) async {
      final List<String> dialled = <String>[];
      PhoneDialer.dial = (p) async {
        dialled.add(p);
        return true;
      };
      addTearDown(() => PhoneDialer.dial = (_) async => false);
      put(user: withContact(sara));
      await pump(tester);
      await scrollTo(tester, find.byKey(const Key('health_contact_call')));
      await tester.tap(find.byKey(const Key('health_contact_call')));
      await tester.pumpAndSettle();
      expect(dialled, <String>['+970599000000']);
      expect(find.byKey(const Key('app_snackbar_error')), findsNothing);
    });

    testWidgets('no dialer: says so and offers Copy', (tester) async {
      PhoneDialer.dial = (_) async => false;
      put(user: withContact(sara));
      await pump(tester);
      await scrollTo(tester, find.byKey(const Key('health_contact_call')));
      await tester.tap(find.byKey(const Key('health_contact_call')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app_snackbar_error')), findsOneWidget);
      expect(find.text("Health_call_failed".tr), findsOneWidget);
    });

    testWidgets('Copy puts the number on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      put(user: withContact(sara));
      await pump(tester);
      await scrollTo(tester, find.byKey(const Key('health_contact_copy')));
      await tester.tap(find.byKey(const Key('health_contact_copy')));
      await tester.pumpAndSettle();
      expect(copied, '+970599000000');
      expect(find.byKey(const Key('app_snackbar_success')), findsOneWidget);
    });

    testWidgets('without a contact: a row to add one', (tester) async {
      put(user: withContact(null));
      await pump(tester);
      await scrollTo(tester, find.byKey(const Key('health_contact_add')));
      expect(find.byKey(const Key('health_contact_call')), findsNothing);
    });

    testWidgets('no profile: one button to fill it in, no Edit link',
        (tester) async {
      put();
      await pump(tester);
      await scrollTo(tester, find.byKey(const Key('health_profile_add')));
      expect(find.text("Health_profile_edit".tr), findsNothing);
    });
  });

  testWidgets('the log shows the 3 latest days, then "Show earlier days"',
      (tester) async {
    put(entries: <HealthEntry>[
      for (int d = 0; d < 5; d++)
        HealthEntry(
            id: 'n$d',
            kind: HealthEntryKind.note,
            at: fixedNow.subtract(Duration(days: d, hours: 1)),
            note: 'Day $d'),
    ]);
    await pump(tester);
    await scrollTo(tester, find.byKey(const Key('health_log_toggle')));
    expect(find.byKey(const Key('health_entry_n2')), findsOneWidget);
    expect(find.byKey(const Key('health_entry_n3')), findsNothing);
    await tester.tap(find.byKey(const Key('health_log_toggle')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('health_entry_n4')));
    expect(find.text("Health_log_show_less".tr), findsOneWidget);
  });

  testWidgets('few days: no toggle', (tester) async {
    put();
    await pump(tester);
    expect(find.byKey(const Key('health_log_toggle')), findsNothing);
  });
}
