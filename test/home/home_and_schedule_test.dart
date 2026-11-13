import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/schedule_summary.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/modules/home/view/home_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() => SessionManager.authUid = () => 'alice');
  tearDown(() {
    SessionManager.authUid = () => null;
    Get.reset();
  });

  group('ScheduleSummary', () {
    test('counts, and progress ignores skipped doses', () {
      final s = ScheduleSummary(
          sampleSchedule(states: <String, String>{
            'bcg_hepb_birth': 'Completed',
            'penta_opv_pcv_1': 'Skipped',
          }),
          fixedNow);
      expect(s.total, 10);
      expect(s.completed, 1);
      expect(s.skipped, 1);
      expect(s.countable, 9);
      expect(s.overdue, 0);
      expect(s.allDone, isFalse);
    });

    test('hero is the oldest overdue dose before any upcoming one', () {
      // Born 15 Jan 2027; on 10 Jun 2027 the birth, 2- and 4-month doses
      // are past. Only the birth dose was given.
      final s = ScheduleSummary(sampleSchedule(), DateTime(2027, 6, 10));
      expect(s.overdue, 2);
      expect(s.hero!.code, 'penta_opv_pcv_1');
    });

    test('hero is the next pending dose when nothing is overdue', () {
      final s = ScheduleSummary(sampleSchedule(), fixedNow);
      expect(s.hero!.code, 'penta_opv_pcv_1'); // due 15 Mar 2027
    });

    test('no hero once everything is given or skipped', () {
      final all = sampleSchedule(states: <String, String>{
        for (final d in sampleSchedule()) d.code!: 'Completed',
      });
      final s = ScheduleSummary(all, fixedNow);
      expect(s.hero, isNull);
      expect(s.allDone, isTrue);
    });
  });

  group('age groups', () {
    test('grouped by schedule age, youngest first', () {
      Get.locale = const Locale('en');
      Get.addTranslations(<String, Map<String, String>>{});
      final groups = groupByAge(sampleSchedule());
      expect(groups.map((g) => g.months),
          <int>[0, 2, 4, 6, 9, 12, 18, 60, 132, 180]);
    });

    test('a dose without a code is placed by the birth date', () {
      final custom = MedicalDatesModel(
          name: 'Check-up',
          description: '',
          date: DateTime(2027, 3, 20),
          state: 'Pending');
      final groups = groupByAge(
          <MedicalDatesModel>[...sampleSchedule(), custom],
          birthday: DateTime(2027, 1, 15));
      expect(groups.firstWhere((g) => g.months == 2).doses, contains(custom));
    });

    test('without a birth date it goes under "Other dates", last', () {
      final custom = MedicalDatesModel(
          name: 'x', description: '', date: DateTime(2027), state: 'Pending');
      final groups =
          groupByAge(<MedicalDatesModel>[...sampleSchedule(), custom]);
      expect(groups.last.months, isNull);
    });
  });

  group('age labels', () {
    testWidgets('English and Arabic plural forms', (tester) async {
      await pumpApp(tester, const SizedBox());
      Get.updateLocale(const Locale('en'));
      await tester.pump();
      expect(ageLabel(0), 'At birth');
      expect(ageLabel(2), '2 months');
      expect(ageLabel(18), '18 months');
      expect(ageLabel(60), '5 years');
      expect(ageLabel(null), 'Other dates');
      Get.updateLocale(const Locale('ar'));
      await tester.pump();
      expect(ageLabel(0), 'عند الولادة');
      expect(ageLabel(2), 'شهران');
      expect(ageLabel(4), '4 أشهر');
      expect(ageLabel(12), '12 شهرًا');
      expect(ageLabel(60), '5 سنوات');
      expect(ageLabel(132), '11 سنةً');
      expect(ageLabel(24), 'سنتان');
    });
  });

  HomeController putHome({
    List<MedicalDatesModel>? doses,
    UserModel? user,
    bool notificationsOn = true,
    Object? error,
  }) {
    final c = HomeController(
      notificationsEnabled: () async => notificationsOn,
      loadUser: (_) async {
        if (error != null) throw error;
        return user ?? sampleUser();
      },
      loadDoses: (_) async => doses ?? sampleSchedule(),
      clock: () => fixedNow,
    );
    Get.put<HomeController>(c);
    return c;
  }

  MedicalDatesController putSchedule({List<MedicalDatesModel>? doses}) {
    final c = MedicalDatesController(
      loadDoses: (_) async => doses ?? sampleSchedule(),
      birthday: () => DateTime(2027, 1, 15),
      clock: () => fixedNow,
    );
    Get.put<MedicalDatesController>(c);
    return c;
  }

  group('HomeView', () {
    for (final Variant v in mainVariants) {
      testWidgets('hero, progress and measurements fit ($v)', (tester) async {
        putHome();
        await pumpApp(tester, const Scaffold(body: HomeView()), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home_hero')), findsOneWidget);
        expect(find.byKey(const Key('home_progress')), findsOneWidget);
        expect(find.text('HomeView_next_dose'.tr), findsOneWidget);
        expectNoOverflow(tester);
        await tester.scrollUntilVisible(
            find.byKey(const Key('home_profile_row')), 200);
        expectNoOverflow(tester);
      });
    }

    testWidgets('the hero leads with an overdue dose', (tester) async {
      final all = sampleSchedule(states: const <String, String>{});
      putHome(doses: all);
      await pumpApp(tester, const Scaffold(body: HomeView()));
      await tester.pumpAndSettle();
      expect(find.text('Overdue dose'), findsOneWidget);
    });

    testWidgets('pending hero shows its countdown with plural forms',
        (tester) async {
      putHome();
      await pumpApp(tester, const Scaffold(body: HomeView()),
          variant: const Variant('ar', Brightness.light, 1.0));
      await tester.pumpAndSettle();
      // Due 15 Mar 2027, five days after fixedNow.
      expect(find.text('متبقٍ 5 أيام'), findsOneWidget);
    });

    testWidgets('all done replaces the hero', (tester) async {
      putHome(
          doses: sampleSchedule(states: <String, String>{
        for (final d in sampleSchedule()) d.code!: 'Completed',
      }));
      await pumpApp(tester, const Scaffold(body: HomeView()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_hero_done')), findsOneWidget);
    });

    testWidgets('notifications-off banner appears on home', (tester) async {
      putHome(notificationsOn: false);
      await pumpApp(tester, const Scaffold(body: HomeView()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notifications_off_banner')), findsOneWidget);
    });

    testWidgets('a load failure shows an inline error with Retry',
        (tester) async {
      putHome(error: FirebaseException(plugin: 'x', code: 'unavailable'));
      await pumpApp(tester, const Scaffold(body: HomeView()));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      putHome();
      await pumpApp(tester, const Scaffold(body: HomeView()));
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('MedicalDatesView', () {
    for (final Variant v in mainVariants) {
      testWidgets('grouped by age with status chips ($v)', (tester) async {
        putSchedule();
        await pumpApp(tester, const Scaffold(body: MedicalDatesView()),
            variant: v);
        await tester.pumpAndSettle();
        expect(find.text(ageLabel(0)), findsOneWidget);
        expect(find.text(ageLabel(2)), findsOneWidget);
        expect(find.text('Completed'.tr), findsWidgets);
        expectNoOverflow(tester);
      });
    }

    testWidgets('Arabic pending chip reads "قيد الانتظار"', (tester) async {
      putSchedule();
      await pumpApp(tester, const Scaffold(body: MedicalDatesView()),
          variant: const Variant('ar', Brightness.light, 1.0));
      await tester.pumpAndSettle();
      expect(find.text('قيد الانتظار'), findsWidgets);
    });

    testWidgets('filters show only that status, and the empty state',
        (tester) async {
      final c = putSchedule();
      await pumpApp(tester, const Scaffold(body: MedicalDatesView()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('filter_completed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_completed')));
      await tester.pumpAndSettle();
      expect(c.groups.expand((g) => g.doses).length, 1);
      await tester.ensureVisible(find.byKey(const Key('filter_skipped')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_skipped')));
      await tester.pumpAndSettle();
      expect(find.text('No doses here'), findsOneWidget);
    });

    testWidgets('doses keep date order (fix: list by date, oldest first)',
        (tester) async {
      final shuffled = sampleSchedule().reversed.toList();
      final c = putSchedule(doses: shuffled);
      await pumpApp(tester, const Scaffold(body: MedicalDatesView()));
      await tester.pumpAndSettle();
      final dates = c.doses.map((d) => d.date).toList();
      expect(dates, List<DateTime>.of(dates)..sort());
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      putSchedule();
      await pumpApp(tester, const Scaffold(body: MedicalDatesView()));
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
