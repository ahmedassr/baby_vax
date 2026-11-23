import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';
import 'package:baby_vax/app/modules/growth/controller/growth_controller.dart';
import 'package:baby_vax/app/modules/growth/model/measurement_model.dart';
import 'package:baby_vax/app/modules/growth/view/growth_view.dart';
import 'package:baby_vax/app/modules/milestones/controller/milestones_controller.dart';
import 'package:baby_vax/app/modules/milestones/model/milestone_record.dart';
import 'package:baby_vax/app/modules/milestones/view/milestone_details_view.dart';
import 'package:baby_vax/app/modules/milestones/widgets/milestone_bar.dart';
import 'package:baby_vax/app/modules/milestones/widgets/milestone_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

/// Lina, born 10 May 2026: 10 months old on [fixedNow] (10 Mar 2027).
UserModel tenMonths() => UserModel(
      uid: 'alice',
      email: 'parent@example.com',
      birthday: '2026-05-10',
      name: 'Lina',
      weight: '',
      height: '',
      headSize: '',
      bloodPercentage: '',
      sex: 'female',
    );

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  group('WHO windows (pinned)', () {
    test('Table II of the 2006 study, 1st to 99th percentile', () {
      final Map<MotorMilestone, (double, double)> who =
          <MotorMilestone, (double, double)>{
        MotorMilestone.sitting: (3.8, 9.2),
        MotorMilestone.standingAssisted: (4.8, 11.4),
        MotorMilestone.crawling: (5.2, 13.5),
        MotorMilestone.walkingAssisted: (5.9, 13.7),
        MotorMilestone.standingAlone: (6.9, 16.9),
        MotorMilestone.walkingAlone: (8.2, 17.6),
      };
      for (final MotorMilestone m in MotorMilestone.values) {
        expect((m.startMonths, m.endMonths), who[m], reason: m.id);
      }
      expect(MotorMilestone.values.map((m) => m.id), <String>[
        'sitting',
        'crawling',
        'standingAssisted',
        'walkingAssisted',
        'standingAlone',
        'walkingAlone',
      ]);
      expect(MotorMilestone.values.where((m) => m.optional),
          <MotorMilestone>[MotorMilestone.crawling]);
    });
  });

  group('MilestoneStatus', () {
    MilestoneStatus of(MotorMilestone m, double? age, [DateTime? at]) =>
        MilestoneStatus.of(milestone: m, achievedAt: at, ageMonths: age);

    test('achieved when a date is recorded, at any age', () {
      for (final double? age in <double?>[null, 1, 10, 30]) {
        expect(of(MotorMilestone.walkingAlone, age, DateTime(2027)),
            MilestoneStatus.achieved);
        expect(of(MotorMilestone.crawling, age, DateTime(2027)),
            MilestoneStatus.achieved);
      }
    });

    test('later before the window, due now inside it, past after it', () {
      const MotorMilestone m = MotorMilestone.sitting;
      expect(of(m, 3.7), MilestoneStatus.later);
      expect(of(m, 3.8), MilestoneStatus.dueNow);
      expect(of(m, 6), MilestoneStatus.dueNow);
      expect(of(m, 9.2), MilestoneStatus.dueNow);
      expect(of(m, 9.3), MilestoneStatus.pastWindow);
      expect(of(m, null), MilestoneStatus.later, reason: 'no birth date');
    });

    test('crawling without a date is optional, never past its window', () {
      for (final double age in <double>[1, 6, 14, 40]) {
        expect(of(MotorMilestone.crawling, age), MilestoneStatus.optional);
      }
    });
  });

  group('MilestoneRecord', () {
    test('round trip, day only, trimmed note', () {
      final MilestoneRecord r = MilestoneRecord(
          milestone: MotorMilestone.sitting,
          achievedAt: DateTime(2026, 12, 12, 15, 30),
          note: '  Sat for a song ');
      final Map<String, dynamic> map = r.toMap();
      expect(map.keys, <String>['achievedAt', 'note']);
      expect((map['achievedAt'] as Timestamp).toDate(), DateTime(2026, 12, 12));
      expect(map['note'], 'Sat for a song');
      final MilestoneRecord back = MilestoneRecord.fromMap('sitting', map)!;
      expect(back.achieved, isTrue);
      expect(back.achievedAt, DateTime(2026, 12, 12));
    });

    test('a note alone is not achieved; unknown ids are ignored', () {
      final MilestoneRecord r =
          MilestoneRecord.fromMap('walkingAlone', <String, dynamic>{
        'note': 'Ask at the visit',
      })!;
      expect(r.achieved, isFalse);
      expect(r.toMap(), <String, dynamic>{'note': 'Ask at the visit'});
      expect(MilestoneRecord.fromMap('running', <String, dynamic>{}), isNull);
      expect(
          const MilestoneRecord(milestone: MotorMilestone.sitting, note: ' ')
              .isEmpty,
          isTrue);
    });

    test('account deletion removes the milestones', () {
      expect(AppPath.userSubcollections('u'), contains('users/u/milestones'));
    });
  });

  group('MilestoneScale', () {
    test('0 to 18 months, longer for an older baby', () {
      expect(MilestoneScale.forAge(10).ticks, <int>[0, 6, 12, 18]);
      expect(MilestoneScale.forAge(null).maxMonths, 18);
      expect(MilestoneScale.forAge(20).ticks, <int>[0, 6, 12, 18, 24]);
      expect(MilestoneScale.forAge(30).ticks, <int>[0, 12, 24, 36]);
      const MilestoneScale s = MilestoneScale(18, 6);
      expect(s.x(0, 180), 0);
      expect(s.x(9, 180), 90);
      expect(s.x(40, 180), 180, reason: 'clamped to the end');
    });

    test('the date must be between the birth date and today', () {
      final DateTime birth = DateTime(2026, 5, 10);
      expect(MilestoneSheet.dateAllowed(fixedNow, fixedNow, birth), isTrue);
      expect(MilestoneSheet.dateAllowed(birth, fixedNow, birth), isTrue);
      expect(MilestoneSheet.dateAllowed(DateTime(2026, 5, 9), fixedNow, birth),
          isFalse);
      expect(MilestoneSheet.dateAllowed(DateTime(2027, 3, 11), fixedNow, birth),
          isFalse);
    });
  });

  late Map<MotorMilestone, MilestoneRecord> store;
  late List<String> asked;
  bool answer = true;

  MilestonesController put({
    Map<MotorMilestone, MilestoneRecord>? records,
    UserModel? user,
  }) {
    store = Map<MotorMilestone, MilestoneRecord>.of(records ??
        <MotorMilestone, MilestoneRecord>{
          MotorMilestone.sitting: MilestoneRecord(
              milestone: MotorMilestone.sitting,
              achievedAt: DateTime(2026, 12, 12)),
          MotorMilestone.standingAssisted: MilestoneRecord(
              milestone: MotorMilestone.standingAssisted,
              achievedAt: DateTime(2027, 2, 1),
              note: 'Holds the sofa'),
        });
    asked = <String>[];
    answer = true;
    final MilestonesController c = MilestonesController(
      load: (_) async => store.values.toList(),
      save: (_, r) async {
        store[r.milestone] = r;
        return WriteOutcome.synced;
      },
      delete: (_, m) async => store.remove(m),
      user: () => user ?? tenMonths(),
      clock: () => fixedNow,
      confirmRemove: (String message) async {
        asked.add(message);
        return answer;
      },
    );
    Get.put<MilestonesController>(c);
    return c;
  }

  void putGrowth() => Get.put<GrowthController>(GrowthController(
        load: (_) async => <MeasurementModel>[],
        save: (_, __) async => WriteOutcome.synced,
        delete: (_, __) async {},
        updateProfile: (_, __) async {},
        user: tenMonths,
        clock: () => fixedNow,
      ));

  group('MilestonesController', () {
    test('statuses for a 10-month-old, and the count', () async {
      final MilestonesController c = put();
      await c.fetch();
      expect(c.achievedCount, 2);
      expect(c.statusOf(MotorMilestone.sitting), MilestoneStatus.achieved);
      expect(c.statusOf(MotorMilestone.crawling), MilestoneStatus.optional);
      expect(c.statusOf(MotorMilestone.walkingAlone), MilestoneStatus.dueNow);
      expect(c.ageNow, closeTo(10, 0.05));
    });

    test('a note alone is kept; clearing it removes the record', () async {
      final MilestonesController c = put();
      await c.fetch();
      await c.saveNote(MotorMilestone.walkingAlone, ' Ask the doctor ');
      expect(store[MotorMilestone.walkingAlone]!.toMap(),
          <String, dynamic>{'note': 'Ask the doctor'});
      expect(c.statusOf(MotorMilestone.walkingAlone), MilestoneStatus.dueNow);
      await c.saveNote(MotorMilestone.walkingAlone, '');
      expect(store.containsKey(MotorMilestone.walkingAlone), isFalse);
      // The note of an achieved milestone keeps its date.
      await c.saveNote(MotorMilestone.sitting, 'At grandma');
      expect(store[MotorMilestone.sitting]!.achievedAt, DateTime(2026, 12, 12));
    });

    test('removing the date keeps the note; no note left deletes it', () async {
      final MilestonesController c = put();
      await c.fetch();
      await c.removeAchievement(MotorMilestone.standingAssisted);
      final MilestoneRecord kept = store[MotorMilestone.standingAssisted]!;
      expect(kept.toMap(), <String, dynamic>{'note': 'Holds the sofa'});
      expect(
          c.statusOf(MotorMilestone.standingAssisted), MilestoneStatus.dueNow,
          reason: 'a note alone is never achieved');
      expect(c.achievedCount, 1);
      await c.removeAchievement(MotorMilestone.sitting);
      expect(store.containsKey(MotorMilestone.sitting), isFalse);
    });

    test('a failed save says so', () async {
      final MilestonesController c = MilestonesController(
        load: (_) async => <MilestoneRecord>[],
        save: (_, __) async => throw Exception('offline'),
        delete: (_, __) async {},
        user: tenMonths,
        clock: () => fixedNow,
      );
      Get.put<MilestonesController>(c);
      expect(
          await c.saveRecord(MilestoneRecord(
              milestone: MotorMilestone.sitting, achievedAt: fixedNow)),
          isFalse);
      expect(c.actionError.value, isNotNull);
    });
  });

  Future<void> pumpList(WidgetTester tester, Variant v) async {
    putGrowth();
    await pumpApp(tester, const GrowthView(), variant: v);
    await tester.tap(find.byKey(const Key('growth_section_milestones')));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const Key('milestones_list')),
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }

  /// The left edge of [key] relative to [bar], over the bar's width.
  double fraction(WidgetTester tester, String key, String bar) {
    final Rect b = tester.getRect(find.byKey(Key(bar)));
    final Rect r = tester.getRect(find.byKey(Key(key)));
    return (r.left - b.left) / b.width;
  }

  group('Milestones list', () {
    for (final Variant v in mainVariants) {
      testWidgets('summary, six cards on one scale, not mirrored ($v)',
          (tester) async {
        put();
        await pumpList(tester, v);
        expect(
            tester
                .widget<AppAddFab>(find.byKey(const Key('growth_add')))
                .visible,
            isFalse,
            reason: 'no measurement FAB on the milestones half');
        final String title = tester
            .widget<Text>(find.byKey(const Key('milestones_summary_title')))
            .data!;
        expect(title, contains('Lina'));
        expect(title, contains(v.rtl ? '10 أشهر' : '10 months'));
        expect(
            tester.widget<Text>(find.byKey(const Key('milestones_count'))).data,
            v.rtl ? '2 من 6 مهارات' : '2 of 6 milestones');
        expect(
            tester
                .widget<LinearProgressIndicator>(
                    find.byKey(const Key('milestones_progress')))
                .value,
            closeTo(2 / 6, 1e-9));
        expectNoOverflow(tester);

        // The scale's 0 is on the left and 18 on the right, in Arabic too.
        expect(
            tester.getCenter(find.byKey(const Key('milestone_tick_0'))).dx,
            lessThan(tester
                .getCenter(find.byKey(const Key('milestone_tick_18')))
                .dx));

        // Sitting: window from 3.8 months, the baby's line at 10, the dot
        // at 7.1 (12 Dec), all measured from the left.
        expect(
            fraction(
                tester, 'milestone_window_sitting', 'milestone_bar_sitting'),
            closeTo(3.8 / 18, 0.01));
        expect(
            fraction(tester, 'milestone_now_sitting', 'milestone_bar_sitting'),
            closeTo(10 / 18, 0.01));
        final Rect bar =
            tester.getRect(find.byKey(const Key('milestone_bar_sitting')));
        final Rect dot =
            tester.getRect(find.byKey(const Key('milestone_dot_sitting')));
        expect(
            (dot.center.dx - bar.left) / bar.width,
            closeTo(
                GrowthReference.ageInMonths(
                        DateTime(2026, 5, 10), DateTime(2026, 12, 12)) /
                    18,
                0.01));
        // The same scale for every card: the baby's line lines up.
        await scrollTo(
            tester, find.byKey(const Key('milestone_card_walkingAlone')));
        expect(
            fraction(tester, 'milestone_now_walkingAlone',
                'milestone_bar_walkingAlone'),
            closeTo(10 / 18, 0.01));
        expect(
            fraction(tester, 'milestone_window_walkingAlone',
                'milestone_bar_walkingAlone'),
            closeTo(8.2 / 18, 0.01));
        expectNoOverflow(tester);
        await scrollTo(tester, find.byKey(const Key('milestones_legend')));
        expectNoOverflow(tester);
      });
    }

    testWidgets('chips, lines and buttons per status', (tester) async {
      put();
      await pumpList(tester, const Variant('en', Brightness.light, 1.0));
      String line(String id) =>
          tester.widget<Text>(find.byKey(Key('milestone_line_$id'))).data!;
      expect(line('sitting'), 'Achieved on Dec 12, 2026');
      expect(find.byKey(const Key('milestone_edit_sitting')), findsOneWidget);
      expect(find.byKey(const Key('milestone_done_sitting')), findsNothing);
      expect(line('crawling'),
          'Some babies skip crawling and go straight to walking');
      expect(
          find.descendant(
              of: find.byKey(const Key('milestone_status_crawling')),
              matching: find.text('Optional')),
          findsOneWidget);
      await scrollTo(
          tester, find.byKey(const Key('milestone_card_walkingAlone')));
      expect(stripBidiIsolates(line('walkingAlone')),
          'Most babies: between 8.2 and 17.6 months');
      expect(
          find.descendant(
              of: find.byKey(const Key('milestone_status_walkingAlone')),
              matching: find.text('Due now')),
          findsOneWidget);
      expect(
          find.byKey(const Key('milestone_done_walkingAlone')), findsOneWidget);
    });

    testWidgets('a younger baby: later, and no warning anywhere',
        (tester) async {
      put(records: <MotorMilestone, MilestoneRecord>{}, user: sampleUser());
      await pumpList(tester, const Variant('en', Brightness.light, 1.0));
      expect(
          find.descendant(
              of: find.byKey(const Key('milestone_status_sitting')),
              matching: find.text('Later')),
          findsOneWidget);
      expect(find.textContaining('delay'), findsNothing);
      expect(find.textContaining('abnormal'), findsNothing);
    });

    testWidgets('Done opens the sheet; Save records today', (tester) async {
      put();
      await pumpList(tester, const Variant('en', Brightness.light, 1.0));
      await scrollTo(
          tester, find.byKey(const Key('milestone_done_walkingAlone')));
      await tester.tap(find.byKey(const Key('milestone_done_walkingAlone')));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(find.byKey(const Key('milestone_sheet_title')))
              .data,
          'Walking alone');
      expect(
          tester
              .widget<Text>(find.byKey(const Key('milestone_sheet_criteria')))
              .data,
          contains('at least five steps'));
      expect(find.text('Between the birth date and today.'), findsOneWidget);
      expect(find.byKey(const Key('milestone_remove')), findsNothing);
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('milestone_note')),
              matching: find.byType(TextField)),
          'In the park');
      await tester.ensureVisible(find.byKey(const Key('milestone_save')));
      await tester.tap(find.byKey(const Key('milestone_save')));
      await tester.pumpAndSettle();
      final MilestoneRecord r = store[MotorMilestone.walkingAlone]!;
      expect(r.achievedAt, DateTime(2027, 3, 10, 12));
      expect(r.note, 'In the park');
      expect(Get.find<MilestonesController>().achievedCount, 3);
      expect(
          find.byKey(const Key('milestone_edit_walkingAlone')), findsOneWidget);
    });

    testWidgets('Edit offers Remove, which asks first', (tester) async {
      put();
      await pumpList(tester, const Variant('en', Brightness.light, 1.0));
      Future<void> remove() async {
        await tester.tap(find.byKey(const Key('milestone_edit_sitting')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('milestone_remove')));
        await tester.tap(find.byKey(const Key('milestone_remove')));
        await tester.pumpAndSettle();
      }

      answer = false;
      await remove();
      expect(asked.single, contains('Sitting without support'));
      expect(store.containsKey(MotorMilestone.sitting), isTrue);
      answer = true;
      await remove();
      expect(store.containsKey(MotorMilestone.sitting), isFalse);
      expect(find.byKey(const Key('milestone_done_sitting')), findsOneWidget);
    });

    testWidgets('a card opens its details', (tester) async {
      put();
      await pumpList(tester, const Variant('en', Brightness.light, 1.0));
      await tester.tap(find.byKey(const Key('milestone_line_crawling')));
      await tester.pumpAndSettle();
      expect(routeStub(AppRoutes.milestoneDetails), findsOneWidget);
    });

    testWidgets('the sheet fits in Arabic dark at 1.3', (tester) async {
      put();
      await pumpList(tester, const Variant('ar', Brightness.dark, 1.3));
      await tester.tap(find.byKey(const Key('milestone_edit_sitting')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('milestone_remove')), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('tap targets and labels', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      put();
      await pumpList(tester, const Variant('ar', Brightness.dark, 1.3));
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('Milestone details', () {
    Future<void> pumpDetails(WidgetTester tester, String id, Variant v) async {
      await pumpApp(tester, MilestoneDetailsView(milestoneId: id), variant: v);
      await tester.pumpAndSettle();
    }

    for (final Variant v in mainVariants) {
      testWidgets('past its window: the calm info card, fits ($v)',
          (tester) async {
        put(records: <MotorMilestone, MilestoneRecord>{});
        await pumpDetails(tester, 'sitting', v);
        expect(find.byKey(const Key('milestone_details_info')), findsOneWidget);
        final AppBanner info = tester
            .widget<AppBanner>(find.byKey(const Key('milestone_details_info')));
        expect(info.tone, AppBannerTone.info, reason: 'never an error');
        expect(
            fraction(
                tester, 'milestone_window_sitting', 'milestone_bar_sitting'),
            closeTo(3.8 / 18, 0.01));
        expectNoOverflow(tester);
        await tester.scrollUntilVisible(
            find.byKey(const Key('milestone_details_record')), 200,
            scrollable: find.byType(Scrollable).first);
        await tester.scrollUntilVisible(
            find.byKey(const Key('milestone_details_source')), 200,
            scrollable: find.byType(Scrollable).first);
        expect(
            tester
                .widget<Text>(find.byKey(const Key('milestone_details_source')))
                .data,
            contains(v.rtl
                ? 'منظمة الصحة العالمية'
                : 'WHO Motor Development Study'));
        expectNoOverflow(tester);
      });
    }

    testWidgets('no info card inside the window, when achieved, or crawling',
        (tester) async {
      put(
          records: <MotorMilestone, MilestoneRecord>{},
          user: UserModel(
            uid: 'alice',
            email: 'p@example.com',
            birthday: '2025-12-10',
            name: 'Lina',
            weight: '',
            height: '',
            headSize: '',
            bloodPercentage: '',
          ));
      // 15 months: crawling's window (to 13.5) has passed.
      await pumpDetails(
          tester, 'crawling', const Variant('en', Brightness.light, 1.0));
      expect(find.byKey(const Key('milestone_details_info')), findsNothing);
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('due now: status and range, no info card', (tester) async {
      put();
      await pumpDetails(
          tester, 'walkingAlone', const Variant('en', Brightness.light, 1.0));
      expect(find.byKey(const Key('milestone_details_info')), findsNothing);
      expect(find.text('Due now'), findsOneWidget);
      expect(
          stripBidiIsolates(tester
              .widget<Text>(find.byKey(const Key('milestone_details_range')))
              .data!),
          'Most babies: between 8.2 and 17.6 months');
      expect(
          tester
              .widget<Text>(find.byKey(const Key('milestone_details_criteria')))
              .data,
          contains('touching no person or object'));
    });

    testWidgets('a note for the doctor visit, without a date', (tester) async {
      put(records: <MotorMilestone, MilestoneRecord>{});
      await pumpDetails(
          tester, 'sitting', const Variant('en', Brightness.light, 1.0));
      await tester.scrollUntilVisible(
          find.byKey(const Key('milestone_details_note')), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('milestone_details_note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('milestone_date')), findsNothing);
      await tester.enterText(
          find.descendant(
              of: find.byKey(const Key('milestone_note')),
              matching: find.byType(TextField)),
          'Ask about sitting');
      await tester.ensureVisible(find.byKey(const Key('milestone_save')));
      await tester.tap(find.byKey(const Key('milestone_save')));
      await tester.pumpAndSettle();
      expect(store[MotorMilestone.sitting]!.toMap(),
          <String, dynamic>{'note': 'Ask about sitting'});
      await tester.scrollUntilVisible(
          find.byKey(const Key('milestone_details_note_text')), -100,
          scrollable: find.byType(Scrollable).first);
      // Still not achieved, so the info card stays.
      await tester.scrollUntilVisible(
          find.byKey(const Key('milestone_details_info')), -100,
          scrollable: find.byType(Scrollable).first);
    });

    testWidgets('record the date from the details', (tester) async {
      put(records: <MotorMilestone, MilestoneRecord>{});
      await pumpDetails(
          tester, 'sitting', const Variant('ar', Brightness.dark, 1.3));
      await tester.scrollUntilVisible(
          find.byKey(const Key('milestone_details_record')), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('milestone_details_record')));
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
      await tester.ensureVisible(find.byKey(const Key('milestone_save')));
      await tester.tap(find.byKey(const Key('milestone_save')));
      await tester.pumpAndSettle();
      expect(store[MotorMilestone.sitting]!.achieved, isTrue);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('milestone_details_info')), findsNothing);
      expect(find.byKey(const Key('milestone_dot_sitting')), findsOneWidget);
      expectNoOverflow(tester);
    });

    testWidgets('tap targets and labels', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      put(records: <MotorMilestone, MilestoneRecord>{});
      await pumpDetails(
          tester, 'sitting', const Variant('ar', Brightness.dark, 1.3));
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
