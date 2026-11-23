// Phone review R4: one feedback component instead of the plain default
// snackbar — success / error / info, leading icon, theme colours, rounded,
// floating, never covering the navigation bar.

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  /// The signed-in shell's shape: a body and a navigation bar.
  Widget shell(VoidCallback onPressed) => Scaffold(
        body: Center(
          child: TextButton(onPressed: onPressed, child: const Text('go')),
        ),
        bottomNavigationBar: NavigationBar(
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'More'),
          ],
        ),
      );

  final Map<AppSnackbarTone, (void Function(String), IconData)> tones =
      <AppSnackbarTone, (void Function(String), IconData)>{
    AppSnackbarTone.success: (
      (m) => AppSnackbar.success(m),
      Icons.check_circle_rounded
    ),
    AppSnackbarTone.error: ((m) => AppSnackbar.error(m), Icons.error_rounded),
    AppSnackbarTone.info: ((m) => AppSnackbar.info(m), Icons.info_rounded),
  };

  for (final Variant v in mainVariants) {
    for (final MapEntry<AppSnackbarTone, (void Function(String), IconData)> t
        in tones.entries) {
      testWidgets(
          '${t.key.name}: icon, theme colours, floating, above the '
          'navigation bar ($v)', (tester) async {
        final String message = v.rtl
            ? 'تم حفظ الملف الشخصي. ستظهر التغييرات في كل مكان.'
            : 'Profile saved. Changes show everywhere.';
        await pumpApp(tester, shell(() => t.value.$1(message)), variant: v);
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();

        final Finder bar = find.byKey(Key('app_snackbar_${t.key.name}'));
        expect(bar, findsOneWidget);
        final SnackBar sb = tester.widget<SnackBar>(bar);
        final ColorScheme scheme =
            Theme.of(tester.element(find.text('go'))).colorScheme;
        final (Color bg, Color fg, IconData icon) =
            AppSnackbar.styleFor(scheme, t.key);
        expect(icon, t.value.$2);
        expect(sb.backgroundColor, bg);
        expect(sb.behavior, SnackBarBehavior.floating);
        expect(sb.shape, isA<RoundedRectangleBorder>());
        expect(find.descendant(of: bar, matching: find.byIcon(t.value.$2)),
            findsOneWidget);
        final Text text = tester.widget<Text>(
            find.descendant(of: bar, matching: find.text(message)));
        expect(text.style?.color, fg);

        // Floating above the navigation bar, not over it.
        final Rect snack = tester.getRect(bar);
        final Rect nav = tester.getRect(find.byType(NavigationBar));
        expect(snack.bottom, lessThanOrEqualTo(nav.top));
        expectNoOverflow(tester);
      });
    }
  }

  testWidgets('a new message replaces the current one', (tester) async {
    await pumpApp(tester, shell(() {
      AppSnackbar.info('first');
      AppSnackbar.success('second');
    }));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);
  });

  testWidgets('errors can be closed and last longer', (tester) async {
    await pumpApp(tester, shell(() => AppSnackbar.error('Could not open')));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    final SnackBar sb =
        tester.widget<SnackBar>(find.byKey(const Key('app_snackbar_error')));
    expect(sb.showCloseIcon, isTrue);
    expect(sb.duration, greaterThan(const Duration(seconds: 4)));
  });

  test('every tone has readable text on its background', () {
    for (final ThemeData t in <ThemeData>[
      AppTheme.lightTheme,
      AppTheme.darkTheme
    ]) {
      for (final AppSnackbarTone tone in AppSnackbarTone.values) {
        final (Color bg, Color fg, _) =
            AppSnackbar.styleFor(t.colorScheme, tone);
        final double l1 = bg.computeLuminance(), l2 = fg.computeLuminance();
        final double ratio = (l1 > l2 ? l1 + 0.05 : l2 + 0.05) /
            (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '${t.brightness.name} ${tone.name}');
      }
    }
  });
}
