import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/modules/setting/controller/setting_controller.dart';
import 'package:baby_vax/app/modules/setting/view/setting_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

Finder field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  setUpAll(initializeDateFormatting);
  tearDown(Get.reset);

  group('MedicalDatesGenerator.rebase', () {
    test('moves generated doses to the new birth date, keeping state', () {
      final doses = sampleSchedule(); // born 15 Jan 2027
      final moved = MedicalDatesGenerator.rebase(doses, DateTime(2027, 1, 20));
      expect(moved, hasLength(doses.length));
      final birth = moved.firstWhere((d) => d.code == 'bcg_hepb_birth');
      expect(birth.date, DateTime(2027, 1, 20));
      expect(birth.state, 'Completed', reason: 'state is kept');
      expect(moved.firstWhere((d) => d.code == 'penta_opv_pcv_1').date,
          DateTime(2027, 3, 20));
    });

    test('same date writes nothing; custom doses are left alone', () {
      final custom = MedicalDatesModel(
          id: 'c',
          name: 'Visit',
          description: '',
          date: DateTime(2027, 2, 1),
          state: 'Pending');
      final moved = MedicalDatesGenerator.rebase(
          <MedicalDatesModel>[...sampleSchedule(), custom],
          DateTime(2027, 1, 15));
      expect(moved, isEmpty);
    });
  });

  group('EditUserView', () {
    late List<UserModel> saved;
    late List<DateTime> rebased;

    EditUserController put({UserModel? user, bool confirm = true}) {
      saved = <UserModel>[];
      rebased = <DateTime>[];
      final c = EditUserController(
        user: user ?? sampleUser(sex: null),
        save: (u) async {
          saved.add(u);
          return WriteOutcome.synced;
        },
        rebaseSchedule: (b) async => rebased.add(b),
        confirm: (_) async => confirm,
        clock: () => fixedNow,
      );
      Get.put<EditUserController>(c);
      return c;
    }

    for (final Variant v in mainVariants) {
      testWidgets('fits a small screen ($v)', (tester) async {
        put();
        await pumpApp(tester, const EditUserView(), variant: v);
        await tester.pumpAndSettle();
        expect(find.text('Lina'), findsOneWidget);
        expectNoOverflow(tester);
      });
    }

    testWidgets('email is shown but cannot be edited', (tester) async {
      put();
      await pumpApp(tester, const EditUserView());
      expect(
          find.byType(TextField).evaluate().map((e) {
            final TextField f = e.widget as TextField;
            return f.controller?.text;
          }),
          isNot(contains('parent@example.com')));
    });

    testWidgets('validates and saves normalised values with the sex',
        (tester) async {
      put();
      await pumpApp(tester, const EditUserView());
      await tester.enterText(field('edit_name'), '');
      await tester.tap(find.byKey(const Key('edit_save')));
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(find.text("Name can't be empty."), findsOneWidget);

      await tester.enterText(field('edit_name'), 'Lina M.');
      await tester.enterText(field('edit_weight'), '4,6');
      await tester.ensureVisible(find.byKey(const Key('edit_sex_male')));
      await tester.tap(find.byKey(const Key('edit_sex_male')));
      await tester.tap(find.byKey(const Key('edit_save')));
      await tester.pumpAndSettle();
      expect(saved.single.name, 'Lina M.');
      expect(saved.single.weight, '4.6');
      expect(saved.single.sex, 'male');
      expect(saved.single.email, 'parent@example.com');
      expect(rebased, isEmpty, reason: 'birthday unchanged');
    });

    testWidgets('changing the birth date asks, then moves the schedule',
        (tester) async {
      final c = put();
      await pumpApp(tester, const EditUserView());
      c.setBirthday(DateTime(2027, 1, 20));
      await tester.tap(find.byKey(const Key('edit_save')));
      await tester.pumpAndSettle();
      expect(saved.single.birthday, '2027-01-20');
      expect(rebased.single, DateTime(2027, 1, 20));
    });

    testWidgets('declining the birth-date change saves nothing',
        (tester) async {
      final c = put(confirm: false);
      await pumpApp(tester, const EditUserView());
      c.setBirthday(DateTime(2027, 1, 20));
      await tester.tap(find.byKey(const Key('edit_save')));
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(rebased, isEmpty);
    });

    testWidgets('a v1.0 "-" name is not carried into the form', (tester) async {
      put(user: UserModel(uid: 'alice', email: 'a@b.co', name: '-'));
      await pumpApp(tester, const EditUserView());
      expect(find.text('-'), findsNothing);
    });
  });

  group('SettingsView', () {
    late Map<String, dynamic> stored;
    late List<String> removed;

    SettingsController put() {
      stored = <String, dynamic>{};
      removed = <String>[];
      final c = SettingsController(
        write: (k, v) async => stored[k] = v,
        remove: removed.add,
        notificationsEnabled: () async => false,
        applyLocale: (l) async => Get.locale = l,
      );
      Get.put<SettingsController>(c);
      return c;
    }

    for (final Variant v in mainVariants) {
      testWidgets('grouped sections fit ($v)', (tester) async {
        put();
        await pumpApp(tester, const Scaffold(body: SettingsView()), variant: v);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('theme_system')), findsOneWidget);
        expectNoOverflow(tester);
        await tester.scrollUntilVisible(
            find.byKey(const Key('settings_delete')), 200);
        expectNoOverflow(tester);
      });
    }

    testWidgets('theme: light and dark are stored, system clears the key',
        (tester) async {
      final c = put();
      await pumpApp(tester, const Scaffold(body: SettingsView()));
      await tester.tap(find.byKey(const Key('theme_dark')));
      await tester.pump();
      expect(stored[StorageKey.isDarkModeKey], isTrue);
      expect(c.themeMode.value, ThemeMode.dark);
      await tester.tap(find.byKey(const Key('theme_system')));
      await tester.pump();
      expect(removed, contains(StorageKey.isDarkModeKey));
    });

    testWidgets('tapping the current language does not switch it',
        (tester) async {
      final c = put();
      await pumpApp(tester, const Scaffold(body: SettingsView()));
      await tester.tap(find.byKey(const Key('language_en')));
      await tester.pumpAndSettle();
      expect(c.currentLanguage.value, 'en');
      expect(stored, isNot(contains(StorageKey.languageKey)));
      await tester.tap(find.byKey(const Key('language_ar')));
      await tester.pumpAndSettle();
      expect(c.currentLanguage.value, 'ar');
      expect(stored[StorageKey.languageKey], 'ar');
      expect(Get.locale?.languageCode, 'ar');
      Get.locale = const Locale('en');
    });

    testWidgets('shows notifications as off', (tester) async {
      put();
      await pumpApp(tester, const Scaffold(body: SettingsView()));
      await tester.pumpAndSettle();
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('tap targets and labels', (tester) async {
      final handle = tester.ensureSemantics();
      put();
      await pumpApp(tester, const Scaffold(body: SettingsView()));
      await tester.pumpAndSettle();
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });
}
