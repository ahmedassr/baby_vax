import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/notification/application/notification_feed.dart';
import 'package:baby_vax/app/modules/notifications/controller/notifications_controller.dart';
import 'package:baby_vax/app/modules/notifications/view/notifications_view.dart';
import 'package:baby_vax/app/modules/notifications/widgets/notification_bell.dart';
import 'package:baby_vax/app/modules/reminders/controller/reminders_controller.dart';
import 'package:baby_vax/app/modules/reminders/model/reminder_model.dart';
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

  late Map<String, Object> storage;

  /// fixedNow: 10 Mar 2027, noon. One overdue dose (8 Mar: two delivered,
  /// earlier), one due on 15 Mar (two upcoming), a daily reminder at 08:00
  /// (yesterday's and today's delivered, tomorrow's upcoming).
  List<MedicalDatesModel> doses() {
    final List<MedicalDatesModel> s = sampleSchedule();
    return <MedicalDatesModel>[
      s[1].copyWith(id: 'late', date: DateTime(2027, 3, 8)),
      s[2].copyWith(id: 'next', date: DateTime(2027, 3, 15)),
    ];
  }

  final List<ReminderModel> reminders = <ReminderModel>[
    ReminderModel(
        id: 'r1',
        title: 'Vitamin D',
        dateTime: DateTime(2027, 2, 1, 8),
        repeat: ReminderRepeat.daily),
  ];

  Future<NotificationsController> put(WidgetTester tester,
      {bool enabled = true,
      List<MedicalDatesModel>? list,
      Map<String, Object>? stored}) async {
    storage = <String, Object>{
      NotificationsController.sinceKey: DateTime(2027, 3, 1).toIso8601String(),
      ...?stored,
    };
    final NotificationsController c = NotificationsController(
      loadReminders: (_) async => reminders,
      doses: () => list ?? doses(),
      readStore: (k) => storage[k],
      writeStore: (k, v) async => storage[k] = v,
      notificationsEnabled: () async => enabled,
      clock: () => fixedNow,
      tick: null,
    );
    Get.put<NotificationsController>(c);
    await c.reload();
    return c;
  }

  test('since is set once, on first use', () {
    storage = <String, Object>{};
    final NotificationsController c = NotificationsController(
      loadReminders: (_) async => reminders,
      doses: () => const <MedicalDatesModel>[],
      readStore: (k) => storage[k],
      writeStore: (k, v) async => storage[k] = v,
      clock: () => fixedNow,
      tick: null,
    );
    expect(c.since, fixedNow);
    expect(
        storage[NotificationsController.sinceKey], fixedNow.toIso8601String());
  });

  group('NotificationsController', () {
    testWidgets('unread counts delivered items only', (tester) async {
      final c = await put(tester);
      // late-advance, late-main, r1 yesterday, r1 today.
      expect(c.unreadCount, 4);
      expect(c.section(FeedSection.today), hasLength(1));
      expect(c.section(FeedSection.upcoming), hasLength(3));
      expect(c.section(FeedSection.earlier).first.at, DateTime(2027, 3, 9, 8),
          reason: 'most recent first');
    });

    testWidgets('mark all as read is stored on the device', (tester) async {
      final c = await put(tester);
      await c.markAllRead();
      expect(c.unreadCount, 0);
      final List<String> saved =
          (storage[NotificationsController.readKey]! as List).cast<String>();
      expect(saved, hasLength(4));
      Get.reset();
      final again = await put(tester,
          stored: <String, Object>{NotificationsController.readKey: saved});
      again.onInit();
      expect(again.unreadCount, 0, reason: 'kept across restarts');
    });
  });

  group('NotificationsView', () {
    for (final Variant v in mainVariants) {
      testWidgets('sections, unread dots, fits ($v)', (tester) async {
        await put(tester);
        await pumpApp(tester, const NotificationsView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('notifications_section_today')),
            findsOneWidget);
        expect(find.byKey(const Key('notifications_section_upcoming')),
            findsOneWidget);
        expect(
            find.byKey(const Key('notification_unread_dot')), findsNWidgets(1),
            reason: 'today\'s, on screen before scrolling');
        expect(find.byKey(const Key('notifications_mark_all')), findsOneWidget);
        expectNoOverflow(tester);
        await tester.scrollUntilVisible(
            find.byKey(const Key('notifications_section_earlier')), 200);
        expectNoOverflow(tester);
      });
    }

    testWidgets('mark all as read clears the dots and the button',
        (tester) async {
      await put(tester);
      await pumpApp(tester, const NotificationsView());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications_mark_all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notification_unread_dot')), findsNothing);
      expect(find.byKey(const Key('notifications_mark_all')), findsNothing);
    });

    testWidgets('tapping a vaccine reminder opens the dose', (tester) async {
      final c = await put(tester);
      await pumpApp(tester, const NotificationsView());
      await tester.pumpAndSettle();
      final Finder late = find.byWidgetPredicate((Widget w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>)
              .value
              .startsWith('notification_late-main@'));
      await tester.scrollUntilVisible(late, 200);
      await tester.tap(late);
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.medicalDateDetails), findsOneWidget);
      expect(
          AppConstant.argumentService
              .getArguments<InternalScreenArgs>()
              ?.medicalDate
              ?.id,
          'late');
      expect(c.unreadCount, 3);
    });

    testWidgets('tapping a custom reminder opens it for editing',
        (tester) async {
      await put(tester);
      await pumpApp(tester, const NotificationsView());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Vitamin D').first);
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.reminders), findsOneWidget);
      expect(Get.arguments, RemindersController.openEditArgument('r1'));
    });

    for (final Variant v in <Variant>[
      const Variant('en', Brightness.light, 1.0),
      const Variant('ar', Brightness.dark, 1.3),
    ]) {
      testWidgets('notifications off: banner to the settings ($v)',
          (tester) async {
        await put(tester, enabled: false);
        await pumpApp(tester, const NotificationsView(), variant: v);
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('notifications_off_banner')), findsOneWidget);
        expect(find.byKey(const Key('open_notification_settings_button')),
            findsOneWidget);
        expectNoOverflow(tester);
      });

      testWidgets('empty state ($v)', (tester) async {
        await put(tester, list: const <MedicalDatesModel>[]);
        Get.find<NotificationsController>().items.clear();
        await pumpApp(tester, const NotificationsView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('notifications_empty')), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('Arabic: Western digits in times', (tester) async {
      await put(tester);
      await pumpApp(tester, const NotificationsView(),
          variant: const Variant('ar', Brightness.light, 1.0));
      await tester.pumpAndSettle();
      final Iterable<String> texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((Text t) => t.data ?? '');
      expect(texts.any((s) => RegExp('[٠-٩]').hasMatch(s)), isFalse);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      await put(tester);
      await pumpApp(tester, const NotificationsView(),
          variant: const Variant('ar', Brightness.dark, 1.3));
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('NotificationBell', () {
    Widget bar() => Scaffold(
          appBar: AppBar(actions: const <Widget>[NotificationBell()]),
        );

    for (final Variant v in mainVariants) {
      testWidgets('badge with the unread count ($v)', (tester) async {
        await put(tester);
        await pumpApp(tester, bar(), variant: v);
        await tester.pumpAndSettle();
        final Badge b =
            tester.widget<Badge>(find.byKey(const Key('notification_badge')));
        expect(b.isLabelVisible, isTrue);
        expect(
            find.descendant(of: find.byType(Badge), matching: find.text('4')),
            findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('no badge when all read; opens the screen', (tester) async {
      final c = await put(tester);
      await c.markAllRead();
      await pumpApp(tester, bar());
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Badge>(find.byKey(const Key('notification_badge')))
              .isLabelVisible,
          isFalse);
      await tester.tap(find.byKey(const Key('notification_bell')));
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.notifications), findsOneWidget);
    });

    testWidgets('the bell is labelled with the count', (tester) async {
      await put(tester);
      await pumpApp(tester, bar());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Notifications, 4 unread'), findsOneWidget);
    });
  });
}
