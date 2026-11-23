// The splash's timing rules (polish §3): full on the first launch, short
// afterwards, a plain fade with reduced motion; a tap skips; it leaves once
// both its animation and start-up work are done, never later.

import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';
import 'package:baby_vax/app/modules/splash/splash_timing.dart';
import 'package:baby_vax/app/modules/splash/splash_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('SplashMode', () {
    test('full only on the first launch', () {
      expect(SplashMode.of(firstLaunch: true, reduceMotion: false),
          SplashMode.full);
      expect(SplashMode.of(firstLaunch: false, reduceMotion: false),
          SplashMode.short);
    });

    test('reduced motion wins on any launch', () {
      expect(SplashMode.of(firstLaunch: true, reduceMotion: true),
          SplashMode.reduced);
      expect(SplashMode.of(firstLaunch: false, reduceMotion: true),
          SplashMode.reduced);
    });

    test('durations: full at most 2.4 s, short at most 0.8 s', () {
      expect(SplashMode.full.duration,
          lessThanOrEqualTo(const Duration(milliseconds: 2400)));
      expect(SplashMode.short.duration,
          lessThanOrEqualTo(const Duration(milliseconds: 800)));
      expect(SplashMode.reduced.duration,
          lessThanOrEqualTo(SplashMode.short.duration));
    });

    test('reduced motion: nothing moves, no shared element', () {
      final SplashPhases p = SplashMode.reduced.phases;
      expect(p.outline, isNull);
      expect(p.wave, isNull);
      expect(p.ring, isNull);
      expect(p.lift, isNull);
      expect(SplashMode.reduced.sharedElement, isFalse);
      expect(SplashMode.full.sharedElement, isTrue);
    });

    test('every phase lies inside its animation', () {
      for (final SplashMode m in SplashMode.values) {
        final SplashPhases p = m.phases;
        for (final Interval? i in <Interval?>[
          p.outline,
          p.wave,
          p.ring,
          p.echo,
          p.lift,
          p.word,
          p.tagline
        ]) {
          if (i == null) continue;
          expect(i.begin, greaterThanOrEqualTo(0));
          expect(i.end, lessThanOrEqualTo(1));
          expect(i.begin, lessThan(i.end));
        }
      }
    });

    test('a phase that does not play is at its end state', () {
      expect(SplashPhases.at(null, 0), 1);
      expect(SplashPhases.at(const Interval(0.5, 1), 0.25), 0);
    });
  });

  group('SplashGate', () {
    test('waits for both, then fires once', () {
      int fired = 0;
      final SplashGate g = SplashGate(onReady: () => fired++);
      g.markAnimationDone();
      expect(fired, 0);
      g.markInitDone();
      expect(fired, 1);
      g.markAnimationDone();
      g.skip();
      expect(fired, 1);
    });

    test('a skip still waits for start-up work', () {
      int fired = 0;
      final SplashGate g = SplashGate(onReady: () => fired++)..skip();
      expect(fired, 0);
      g.markInitDone();
      expect(fired, 1);
    });
  });

  group('SplashView', () {
    late List<String> routes;
    late bool seen;
    late int marked;

    setUp(() {
      routes = <String>[];
      seen = false;
      marked = 0;
      Get.testMode = true;
    });
    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester,
        {Future<void>? startup, bool reduce = false}) async {
      Get.put<SplashController>(SplashController(
        readFlag: (String k) => k == StorageKey.hasSeenSplashKey && seen,
        setFlag: (String k) => marked++,
        startup: startup ?? Future<void>.value(),
        navigate: routes.add,
      ));
      await pumpApp(
          tester,
          reduce
              ? const MediaQuery(
                  data: MediaQueryData(disableAnimations: true),
                  child: SplashView())
              : const SplashView(),
          settle: false);
    }

    testWidgets('first launch: full animation, then routes', (tester) async {
      await pump(tester);
      expect(marked, 1, reason: 'the full splash is remembered');
      await tester.pump(const Duration(milliseconds: 2300));
      expect(routes, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      expect(routes, <String>[AppRoutes.onboarding]);
    });

    testWidgets('later launches: the short version', (tester) async {
      seen = true;
      await pump(tester);
      expect(marked, 0);
      await tester.pump(const Duration(milliseconds: 700));
      expect(routes, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      expect(routes, hasLength(1));
    });

    testWidgets('a tap skips the animation', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('splash_skip')));
      await tester.pump();
      expect(routes, hasLength(1));
    });

    testWidgets('slow start-up: waits for it, not longer', (tester) async {
      seen = true;
      final Completer<void> startup = Completer<void>();
      await pump(tester, startup: startup.future);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(routes, isEmpty, reason: 'animation done, start-up is not');
      startup.complete();
      await tester.pump();
      expect(routes, hasLength(1));
    });

    testWidgets('reduced motion: a short fade, no shared element',
        (tester) async {
      await pump(tester, reduce: true);
      expect(find.byType(Hero), findsNothing);
      await tester.pump(const Duration(milliseconds: 450));
      expect(routes, hasLength(1));
    });

    testWidgets('fits a small phone in Arabic dark', (tester) async {
      seen = true;
      Get.put<SplashController>(SplashController(
        readFlag: (String k) => k == StorageKey.hasSeenSplashKey,
        setFlag: (_) {},
        startup: Future<void>.value(),
        navigate: routes.add,
      ));
      await pumpApp(tester, const SplashView(),
          variant: const Variant('ar', Brightness.dark, 1.3), settle: false);
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Baby Vax'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
