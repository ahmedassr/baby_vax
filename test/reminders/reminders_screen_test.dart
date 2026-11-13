import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/reminders/controller/reminders_controller.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';
import 'package:baby_vax/app/modules/reminders/view/reminders_view.dart';
import 'package:baby_vax/app/modules/reminders/widgets/reminder_sheet.dart';
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

  late List<ReminderModel> store;
  late List<String> scheduled;
  late List<String> cancelled;

  RemindersController put({List<ReminderModel>? items}) {
    store = List<ReminderModel>.of(items ??
        <ReminderModel>[
          ReminderModel(
              id: 'r1',
              title: 'قطرات فيتامين د',
              dateTime: DateTime(2027, 1, 1, 8),
              repeat: ReminderRepeat.daily),
          ReminderModel(
              id: 'r2',
              title: 'Doctor visit at the UNRWA clinic, second floor',
              note: 'Bring the vaccination card',
              dateTime: DateTime(2027, 3, 20, 10, 30)),
          ReminderModel(
              id: 'r3', title: 'Old', dateTime: DateTime(2027, 2, 1, 9)),
        ]);
    scheduled = <String>[];
    cancelled = <String>[];
    final c = RemindersController(
      load: (_) async => List<ReminderModel>.of(store),
      save: (_, r) async {
        final String id = r.id ?? 'new';
        store.removeWhere((x) => x.id == id);
        store.add(r.copyWith(id: id));
        return (id, WriteOutcome.synced);
      },
      delete: (_, id) async => store.removeWhere((x) => x.id == id),
      schedule: (r) async {
        scheduled.add(r.id!);
        return true;
      },
      cancel: (id) async => cancelled.add(id),
      clock: () => fixedNow,
    );
    Get.put<RemindersController>(c);
    return c;
  }

  group('RemindersController', () {
    test('upcoming first by next time, past one-offs last', () async {
      final c = put();
      await c.fetch();
      expect(c.sorted.map((r) => r.id), <String>['r1', 'r2', 'r3']);
    });

    test('saving schedules; turning off only cancels', () async {
      final c = put();
      await c.fetch();
      await c.saveReminder(
          ReminderModel(title: 'Follow-up', dateTime: DateTime(2027, 4, 1, 9)));
      expect(scheduled, <String>['new']);
      expect(cancelled, <String>['new'], reason: 'cancel-then-schedule');
      await c.setEnabled(c.items.firstWhere((r) => r.id == 'r2'), false);
      expect(cancelled.last, 'r2');
      expect(scheduled, isNot(contains('r2')));
    });

    test('delete cancels the notification and removes it', () async {
      final c = put();
      await c.fetch();
      await c.deleteReminder(c.items.first);
      expect(cancelled, contains('r1'));
      expect(c.items.map((r) => r.id), isNot(contains('r1')));
    });

    test('a blank title is never saved', () async {
      final c = put(items: <ReminderModel>[]);
      expect(
          await c.saveReminder(
              ReminderModel(title: '  ', dateTime: DateTime(2027, 4, 1))),
          isFalse);
    });
  });

  group('RemindersView', () {
    for (final Variant v in mainVariants) {
      testWidgets('list fits ($v)', (tester) async {
        put();
        await pumpApp(tester, const RemindersView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('reminder_switch_r1')), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('times use Western digits in Arabic', (tester) async {
      put();
      await pumpApp(tester, const RemindersView(),
          variant: const Variant('ar', Brightness.light, 1.0));
      await tester.pumpAndSettle();
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(RegExp('[٠-٩]').hasMatch(texts), isFalse);
      expect(texts, contains('كل يوم'));
    });

    testWidgets('a past one-off cannot be switched on', (tester) async {
      put();
      await pumpApp(tester, const RemindersView());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const Key('reminder_switch_r3')), 200,
          scrollable: find.byType(Scrollable).first);
      final Switch s =
          tester.widget<Switch>(find.byKey(const Key('reminder_switch_r3')));
      expect(s.onChanged, isNull);
    });

    testWidgets('empty state offers to add', (tester) async {
      put(items: <ReminderModel>[]);
      await pumpApp(tester, const RemindersView());
      await tester.pumpAndSettle();
      expect(find.text('No reminders yet'), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pumpApp(tester, const RemindersView());
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('ReminderSheet', () {
    Future<List<ReminderSheetResult?>> open(WidgetTester tester,
        {ReminderModel? initial, Variant? variant}) async {
      final List<ReminderSheetResult?> out = <ReminderSheetResult?>[];
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => out.add(
                  await ReminderSheet.show(now: fixedNow, initial: initial)),
              child: const Text('open'),
            ),
          ),
        ),
        variant: variant ?? const Variant('en', Brightness.light, 1.0),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return out;
    }

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    for (final Variant v in mainVariants) {
      testWidgets('fits ($v)', (tester) async {
        await open(tester, variant: v);
        expectNoOverflow(tester);
      });
    }

    testWidgets('title required; suggestion fills it; defaults to tomorrow 9',
        (tester) async {
      final out = await open(tester);
      await tapKey(tester, 'reminder_save');
      expect(out, isEmpty);
      expect(find.text('Please give the reminder a name.'), findsOneWidget);
      await tester.tap(find.text('Vitamin D drops'));
      await tester.pump();
      await tapKey(tester, 'reminder_repeat_daily');
      await tapKey(tester, 'reminder_save');
      final r = (out.single as SaveReminder).reminder;
      expect(r.title, 'Vitamin D drops');
      expect(r.repeat, ReminderRepeat.daily);
      expect(r.dateTime, DateTime(2027, 3, 11, 9));
    });

    testWidgets('a past one-off is refused, a repeating one is not',
        (tester) async {
      final out = await open(tester,
          initial: ReminderModel(
              id: 'x', title: 'Old', dateTime: DateTime(2027, 2, 1, 9)));
      await tapKey(tester, 'reminder_save');
      expect(find.byKey(const Key('reminder_when_error')), findsOneWidget);
      await tapKey(tester, 'reminder_repeat_weekly');
      await tapKey(tester, 'reminder_save');
      expect(
          (out.single as SaveReminder).reminder.repeat, ReminderRepeat.weekly);
    });

    testWidgets('editing offers delete', (tester) async {
      final out = await open(tester,
          initial: ReminderModel(
              id: 'x', title: 'Doctor', dateTime: DateTime(2027, 4, 1, 9)));
      await tapKey(tester, 'reminder_delete');
      expect(out.single, isA<DeleteReminder>());
    });
  });
}
