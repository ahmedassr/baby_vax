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

  MedicalDateDetailsController put(MedicalDatesModel dose,
      {bool confirmAnswer = true}) {
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

  testWidgets('skip is offered for a pending dose', (tester) async {
    put(pendingFuture());
    await pumpApp(tester, const MedicalDateDetailsView());
    await tap(tester, 'mark_skipped_button');
    expect(writer.writes.single.$2, MedicalDateStateEnum.skipped);
  });

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
