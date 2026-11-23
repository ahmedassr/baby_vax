import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

MedicalDatesModel dose({
  String state = 'Pending',
  required DateTime date,
  String code = 'penta_opv_pcv_1',
}) =>
    MedicalDatesModel(
      id: 'd1',
      code: code,
      name: 'fallback',
      description: '',
      date: date,
      state: state,
    );

void main() {
  tearDown(Get.reset);

  final DateTime now = DateTime(2027, 3, 10, 12);

  group('VaccineStatePolicy.displayStatus', () {
    test('stored states map through, a past pending dose is overdue', () {
      expect(
          VaccineStatePolicy.displayStatus(
              dose(date: DateTime(2027, 3, 20)), now),
          DoseDisplayStatus.pending);
      expect(
          VaccineStatePolicy.displayStatus(
              dose(date: DateTime(2027, 3, 10)), now),
          DoseDisplayStatus.pending,
          reason: 'due today is not overdue');
      expect(
          VaccineStatePolicy.displayStatus(
              dose(date: DateTime(2027, 3, 9)), now),
          DoseDisplayStatus.overdue);
      expect(
          VaccineStatePolicy.displayStatus(
              dose(state: 'Completed', date: DateTime(2027, 1, 1)), now),
          DoseDisplayStatus.completed,
          reason: 'a past completed dose is not overdue');
      expect(
          VaccineStatePolicy.displayStatus(
              dose(state: 'Skipped', date: DateTime(2027, 1, 1)), now),
          DoseDisplayStatus.skipped);
    });
  });

  group('AppStatusChip', () {
    for (final Variant v in mainVariants) {
      testWidgets('renders every status with its label and icon ($v)',
          (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Wrap(children: <Widget>[
              for (final s in DoseDisplayStatus.values) AppStatusChip(status: s)
            ]),
          ),
          variant: v,
        );
        for (final s in DoseDisplayStatus.values) {
          expect(find.text(s.translationKey.tr), findsOneWidget);
          expect(find.byIcon(AppStatusChip.iconFor(s)), findsOneWidget);
        }
        expectNoOverflow(tester);
      });
    }

    testWidgets('Arabic pending reads "قيد الانتظار"', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: AppStatusChip(status: DoseDisplayStatus.pending)),
        variant: const Variant('ar', Brightness.light, 1.0),
      );
      expect(find.text('قيد الانتظار'), findsOneWidget);
    });

    testWidgets('is announced as a status', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
          tester,
          const Scaffold(
              body: AppStatusChip(status: DoseDisplayStatus.overdue)));
      expect(find.bySemanticsLabel('Status: Overdue'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppDoseTile', () {
    for (final Variant v in mainVariants) {
      testWidgets('long name wraps to two lines without overflow ($v)',
          (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: ListView(padding: AppSpacing.screen, children: <Widget>[
              AppDoseTile(
                // The longest generated Arabic name.
                dose: dose(
                    code: 'penta_opv_mmr_2_booster',
                    date: DateTime(2027, 5, 10)),
                now: now,
                onTap: () {},
              ),
            ]),
          ),
          variant: v,
        );
        final Text title = tester.widget<Text>(
            find.textContaining(v.rtl ? 'جرعة معززة' : 'Booster DTP'));
        expect(title.maxLines, 2);
        expect(title.overflow, TextOverflow.ellipsis);
        expectNoOverflow(tester);
      });
    }

    testWidgets('pending shows the countdown, completed does not',
        (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Column(children: <Widget>[
            AppDoseTile(dose: dose(date: DateTime(2027, 3, 13)), now: now),
            AppDoseTile(
                dose: dose(state: 'Completed', date: DateTime(2027, 3, 13)),
                now: now),
          ]),
        ),
      );
      expect(find.textContaining('3 days left'), findsOneWidget);
    });

    testWidgets('Arabic countdown uses the dual form', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
            body:
                AppDoseTile(dose: dose(date: DateTime(2027, 3, 12)), now: now)),
        variant: const Variant('ar', Brightness.light, 1.0),
      );
      expect(find.textContaining('متبقٍ يومان'), findsOneWidget);
    });

    testWidgets('is one tap target, at least 48dp, with a full label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Scaffold(
          body: ListView(children: <Widget>[
            AppDoseTile(
                dose: dose(date: DateTime(2027, 3, 9)), now: now, onTap: () {}),
          ]),
        ),
      );
      expect(
          find.bySemanticsLabel(RegExp(r'First DTP-HepB-Hib.*Overdue.*2027')),
          findsOneWidget);
      await expectTapTargets(tester);
      await expectLabelledTargets(tester);
      handle.dispose();
    });
  });

  group('AppButton', () {
    for (final variant in AppButtonVariant.values) {
      testWidgets('$variant is at least 48dp tall', (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            body: Center(
              child: AppButton(text: 'Go', onPressed: () {}, variant: variant),
            ),
          ),
        );
        expect(tester.getSize(find.byType(AppButton)).height,
            greaterThanOrEqualTo(48));
      });
    }

    testWidgets('loading keeps the size and ignores taps', (tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Scaffold(
          body: Center(
            child:
                AppButton(text: 'Save', onPressed: () => taps++, loading: true),
          ),
        ),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('primary label meets AA on its fill in both themes',
        (tester) async {
      for (final ThemeData t in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final s = t.colorScheme;
        // Measured in app_theme_test; asserted here against the button's
        // own resolved style so a theme edit cannot drift.
        final ButtonStyle style = t.elevatedButtonTheme.style!;
        expect(style.backgroundColor!.resolve(<WidgetState>{}), s.primary);
        expect(style.foregroundColor!.resolve(<WidgetState>{}), s.onPrimary);
      }
    });
  });

  group('AppField', () {
    testWidgets('password field toggles visibility with a labelled button',
        (tester) async {
      final handle = tester.ensureSemantics();
      final c = TextEditingController(text: 'secret');
      await pumpApp(
        tester,
        Scaffold(
          body: Padding(
            padding: AppSpacing.screen,
            child:
                AppField(label: 'Password', controller: c, obscureText: true),
          ),
        ),
      );
      expect(
          tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
      await tester.tap(find.byTooltip('Show'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
          isFalse);
      await expectLabelledTargets(tester);
      handle.dispose();
    });

    testWidgets('shows the error instead of the helper', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AppField(
            label: 'Email',
            controller: TextEditingController(),
            helper: 'We never share it',
            errorText: 'Required',
          ),
        ),
      );
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('We never share it'), findsNothing);
    });

    testWidgets('optional adds the suffix to the label', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: AppField(
              label: 'Weight',
              controller: TextEditingController(),
              optional: true,
              suffixText: 'kg'),
        ),
        variant: const Variant('ar', Brightness.light, 1.0),
      );
      expect(find.text('Weight (اختياري)'), findsOneWidget);
    });
  });

  group('states', () {
    for (final Variant v in mainVariants) {
      testWidgets('empty and error states fit a small screen ($v)',
          (tester) async {
        await pumpApp(
          tester,
          Scaffold(
            // Built lazily so .tr runs after GetMaterialApp has loaded the
            // translations for this variant's locale.
            body: Builder(
                builder: (_) => Column(children: <Widget>[
                      Expanded(
                        child: AppEmptyState(
                          title: 'state_empty_title'.tr,
                          message: 'MedicalDisclaimer_body'.tr,
                          actionLabel: 'retry_label'.tr,
                          onAction: () {},
                        ),
                      ),
                      Expanded(child: AppErrorState(onRetry: () {})),
                    ])),
          ),
          variant: v,
        );
        expect(find.text('retry_label'.tr), findsNWidgets(2));
        expectNoOverflow(tester);
      });
    }

    testWidgets('loading skeleton is announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Scaffold(body: AppLoading()), settle: false);
      await tester.pump();
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('AppProgressRing', () {
    testWidgets('reads as a count, not a percentage', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
          tester,
          const Scaffold(
              body: Center(child: AppProgressRing(done: 3, total: 10))));
      expect(find.bySemanticsLabel('3 of 10 doses done'), findsOneWidget);
      handle.dispose();
    });

    test('fraction is clamped and safe on an empty schedule', () {
      expect(const AppProgressRing(done: 0, total: 0).fraction, 0);
      expect(const AppProgressRing(done: 5, total: 4).fraction, 1);
    });
  });

  group('AppListRow', () {
    testWidgets('mirrors its chevron in RTL', (tester) async {
      await pumpApp(
        tester,
        Scaffold(body: AppListRow(title: 'x', onTap: () {})),
        variant: const Variant('ar', Brightness.light, 1.0),
      );
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });

    testWidgets('is at least 48dp', (tester) async {
      await pumpApp(
          tester, Scaffold(body: AppListRow(title: 'x', onTap: () {})));
      expect(tester.getSize(find.byType(AppListRow)).height,
          greaterThanOrEqualTo(48));
    });
  });

  testWidgets('AppStepHeader names the step for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
        tester,
        const Scaffold(
            body: AppStepHeader(current: 1, total: 5, title: 'Baby')));
    expect(find.bySemanticsLabel('Step 2 of 5, Baby'), findsOneWidget);
    handle.dispose();
  });
}
