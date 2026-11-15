import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/modules/medical_date_details/view/medical_date_details_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';
import '../service/vaccine_state_service_test.dart'
    show FakeReminders, FakeWriter;

void main() {
  tearDown(Get.reset);

  late FakeWriter writer;
  late FakeReminders reminders;
  late List<String> confirmations;
  late List<bool> sheetsOpened;

  MedicalDateDetailsController put(MedicalDatesModel dose,
      {bool confirmAnswer = true,
      DoseRecord? sheetResult = const DoseRecord()}) {
    sheetsOpened = <bool>[];
    writer = FakeWriter();
    reminders = FakeReminders();
    confirmations = <String>[];
    final c = MedicalDateDetailsController(
      dose: dose,
      stateService: VaccineStateService(writer: writer, reminders: reminders),
      confirm: (m) async {
        confirmations.add(m);
        return confirmAnswer;
      },
      recordSheet: (initial, {required bool editing}) async {
        sheetsOpened.add(editing);
        return sheetResult;
      },
      clock: () => fixedNow,
    );
    Get.put<MedicalDateDetailsController>(c);
    return c;
  }

  MedicalDatesModel pendingFuture() => sampleSchedule()[1]; // 15 Mar 2027
  MedicalDatesModel completed() => sampleSchedule()[0];

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  for (final Variant v in mainVariants) {
    testWidgets('fits a small screen with the 2-line title ($v)',
        (tester) async {
      put(sampleSchedule()[6]); // the longest generated name
      await pumpApp(tester, const MedicalDateDetailsView(), variant: v);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mark_completed_button')), findsOneWidget);
      expectNoOverflow(tester);
      await tester.scrollUntilVisible(find.byType(MedicalDisclaimer), 200,
          scrollable: find.byType(Scrollable).first);
      expectNoOverflow(tester);
    });
  }

  testWidgets('marking a future dose asks first; "no" changes nothing',
      (tester) async {
    put(pendingFuture(), confirmAnswer: false);
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_completed_button');
    expect(confirmations, hasLength(1));
    expect(writer.writes, isEmpty);
  });

  testWidgets('"yes" marks it given and cancels its reminders', (tester) async {
    final c = put(pendingFuture());
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_completed_button');
    expect(writer.writes.single.$2, MedicalDateStateEnum.completed);
    expect(reminders.cancelled, <String>['dose1']);
    expect(c.dose.value!.state, 'Completed');
    expect(find.byKey(const Key('undo_button')), findsOneWidget);
  });

  testWidgets('a past dose is marked without asking', (tester) async {
    put(sampleSchedule(states: const <String, String>{})[0]); // birth, past
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_completed_button');
    expect(confirmations, isEmpty);
    expect(writer.writes, hasLength(1));
  });

  testWidgets('undo puts it back to pending and restores reminders',
      (tester) async {
    put(completed());
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'undo_button');
    expect(writer.writes.single.$2, MedicalDateStateEnum.pending);
    expect(reminders.scheduled.single.id, 'dose0');
    expect(find.byKey(const Key('mark_completed_button')), findsOneWidget);
  });

  // Phone review R7: "Mark as skipped" stays among the main actions for a
  // dose that is overdue or due today; for a future dose it moves to the
  // "More options" menu and asks first.
  final MedicalDatesModel overdue =
      sampleSchedule(states: const <String, String>{})[0]; // 15 Jan, pending
  final MedicalDatesModel dueToday =
      sampleSchedule()[1].copyWith(date: DateTime(2027, 3, 10));

  for (final Variant v in const <Variant>[
    Variant('en', Brightness.light, 1.0),
    Variant('ar', Brightness.dark, 1.3),
  ]) {
    for (final (String name, MedicalDatesModel dose) in <(
      String,
      MedicalDatesModel
    )>[('overdue', overdue), ('due today', dueToday)]) {
      testWidgets('$name: skip stays a main action, no menu ($v)',
          (tester) async {
        put(dose);
        await pumpApp(tester, const MedicalDateDetailsView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mark_skipped_button')), findsOneWidget);
        expect(find.byKey(const Key('dose_more_options')), findsNothing);
        expectNoOverflow(tester);
        await tap(tester, 'mark_skipped_button');
        expect(writer.writes.single.$2, MedicalDateStateEnum.skipped);
        expect(confirmations, isEmpty, reason: 'unchanged: no extra question');
      });
    }

    testWidgets('future: skip only in More options, confirmed, undoable ($v)',
        (tester) async {
      final c = put(pendingFuture());
      await pumpApp(tester, const MedicalDateDetailsView(), variant: v);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mark_skipped_button')), findsNothing);
      expect(find.byKey(const Key('mark_completed_button')), findsOneWidget);
      expect(
          find.byTooltip("MedicalDateDetails_more_options".tr), findsOneWidget);
      expectNoOverflow(tester);

      await tap(tester, 'dose_more_options');
      expect(find.text("MedicalDateActions_mark_skipped".tr), findsOneWidget);
      await tap(tester, 'menu_mark_skipped');

      // Asked first: reminders cancelled; check with the doctor or the
      // national schedule.
      expect(confirmations.single, "MedicalDateDetails_confirm_skip_msg".tr);
      expect(
          confirmations.single,
          contains(
              v.rtl ? 'جدول التطعيم الوطني' : 'national vaccination schedule'));
      expect(confirmations.single,
          contains(v.rtl ? 'ستُلغى تذكيراتها' : 'reminders will be cancelled'));
      expect(writer.writes.single.$2, MedicalDateStateEnum.skipped);
      expect(reminders.cancelled, <String>['dose1']);
      expect(c.dose.value!.state, 'Skipped');
      expect(find.byKey(const Key('dose_more_options')), findsNothing);

      // Undo brings the dose and its reminders back.
      await tap(tester, 'undo_button');
      expect(writer.writes.last.$2, MedicalDateStateEnum.pending);
      expect(reminders.scheduled.single.id, 'dose1');
      expect(find.byKey(const Key('dose_more_options')), findsOneWidget);
    });

    testWidgets('future: declining the question changes nothing ($v)',
        (tester) async {
      final c = put(pendingFuture(), confirmAnswer: false);
      await pumpApp(tester, const MedicalDateDetailsView(), variant: v);
      await tester.pumpAndSettle();
      await tap(tester, 'dose_more_options');
      await tap(tester, 'menu_mark_skipped');
      expect(confirmations, hasLength(1));
      expect(writer.writes, isEmpty);
      expect(reminders.cancelled, isEmpty);
      expect(c.dose.value!.state, 'Pending');
    });
  }

  testWidgets('offline shows "Saved on this phone"', (tester) async {
    put(completed());
    writer.outcome = WriteOutcome.pendingSync;
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'undo_button');
    expect(find.byKey(const Key('details_saved_offline')), findsOneWidget);
    expect(find.textContaining('Saved on this phone'), findsOneWidget);
  });

  testWidgets('a failed write keeps the screen and shows a banner',
      (tester) async {
    final c = put(completed());
    writer.failWith = Exception('denied');
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'undo_button');
    expect(find.byKey(const Key('details_error')), findsOneWidget);
    expect(c.dose.value!.state, 'Completed');
  });

  testWidgets('opened without a dose shows a way back', (tester) async {
    Get.put<MedicalDateDetailsController>(MedicalDateDetailsController(
        stateService: VaccineStateService(
            writer: FakeWriter(), reminders: FakeReminders())));
    await pumpApp(tester, const MedicalDateDetailsView());
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('dismissing the record sheet changes nothing', (tester) async {
    put(pendingFuture(), sheetResult: null);
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_completed_button');
    expect(sheetsOpened, <bool>[false]);
    expect(writer.writes, isEmpty);
  });

  testWidgets('a filled record is saved with the dose and shown',
      (tester) async {
    final c = put(pendingFuture(),
        sheetResult: DoseRecord(
            givenDate: DateTime(2027, 3, 10),
            clinic: 'Ramallah MCH',
            lot: 'AB1234'));
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_completed_button');
    expect(writer.records.single!.lot, 'AB1234');
    expect(c.hasRecord, isTrue);
    await tester.scrollUntilVisible(
        find.byKey(const Key('record_section')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Ramallah MCH'), findsOneWidget);
    expect(find.textContaining('AB1234'), findsOneWidget);
  });

  testWidgets('the record of a given dose can be edited later', (tester) async {
    put(completed(), sheetResult: const DoseRecord(clinic: 'UNRWA clinic'));
    await pumpApp(tester, const MedicalDateDetailsView());
    await tester.tap(find.text('Add details'));
    await tester.pumpAndSettle();
    expect(sheetsOpened, <bool>[true]);
    expect(writer.recordWrites.single.$2.clinic, 'UNRWA clinic');
    expect(writer.writes, isEmpty, reason: 'state unchanged');
  });

  testWidgets('a record left on a pending dose is not shown', (tester) async {
    final c = put(pendingFuture()
        .copyWith(record: const DoseRecord(clinic: 'left by v1.0 undo')));
    await pumpApp(tester, const MedicalDateDetailsView());
    expect(c.hasRecord, isFalse);
    expect(find.textContaining('left by v1.0'), findsNothing);
  });

  testWidgets('tap targets and labels', (tester) async {
    final handle = tester.ensureSemantics();
    put(pendingFuture());
    await pumpApp(tester, const MedicalDateDetailsView());
    await tester.pumpAndSettle();
    await expectTapTargets(tester);
    await expectLabelledTargets(tester);
    handle.dispose();
  });
}
