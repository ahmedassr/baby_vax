import 'package:flutter/animation.dart';

/// Which splash plays (polish §3).
enum SplashMode {
  /// The whole "protection bloom", once, on the first launch after install.
  full,

  /// A short version on every later launch.
  short,

  /// "Remove animations" is on: the name fades in, nothing moves.
  reduced;

  /// The mode for this launch. Reduced motion always wins.
  static SplashMode of(
      {required bool firstLaunch, required bool reduceMotion}) {
    if (reduceMotion) return SplashMode.reduced;
    return firstLaunch ? SplashMode.full : SplashMode.short;
  }

  /// How long this mode's animation runs.
  Duration get duration => switch (this) {
        SplashMode.full => const Duration(milliseconds: 2400),
        SplashMode.short => const Duration(milliseconds: 800),
        SplashMode.reduced => const Duration(milliseconds: 400),
      };

  /// When each part of the animation plays, as fractions of [duration].
  SplashPhases get phases => switch (this) {
        SplashMode.full => SplashPhases.fromMs(
            total: 2400,
            outline: (0, 700),
            wave: (150, 1150),
            ring: (650, 1550),
            echo: (900, 1800),
            lift: (900, 1500),
            word: (1100, 1850),
            tagline: (1700, 2100),
          ),
        SplashMode.short => SplashPhases.fromMs(
            total: 800,
            outline: null,
            wave: null,
            ring: (0, 600),
            echo: null,
            lift: (0, 400),
            word: (150, 550),
            tagline: (350, 700),
          ),
        SplashMode.reduced => SplashPhases.fromMs(
            total: 400,
            outline: null,
            wave: null,
            ring: null,
            echo: null,
            lift: null,
            word: (0, 300),
            tagline: (100, 400),
          ),
      };

  /// Whether the wordmark rises letter by letter (only the full splash).
  bool get letterByLetter => this == SplashMode.full;

  /// Whether the mark flies into the first screen afterwards. Not with
  /// reduced motion: the next screen simply appears.
  bool get sharedElement => this != SplashMode.reduced;
}

/// The intervals of one splash animation. A null interval means that part
/// does not play in this mode (it is drawn in its end state, or not at all).
class SplashPhases {
  const SplashPhases({
    this.outline,
    this.wave,
    this.ring,
    this.echo,
    this.lift,
    this.word,
    this.tagline,
  });

  factory SplashPhases.fromMs({
    required int total,
    required (int, int)? outline,
    required (int, int)? wave,
    required (int, int)? ring,
    required (int, int)? echo,
    required (int, int)? lift,
    required (int, int)? word,
    required (int, int)? tagline,
  }) {
    Interval? i((int, int)? r) =>
        r == null ? null : Interval(r.$1 / total, r.$2 / total);
    return SplashPhases(
      outline: i(outline),
      wave: i(wave),
      ring: i(ring),
      echo: i(echo),
      lift: i(lift),
      word: i(word),
      tagline: i(tagline),
    );
  }

  /// A light line traces the shield's outline.
  final Interval? outline;

  /// A soft wave of light rises through the shield and settles.
  final Interval? wave;

  /// A ring ripples out from the mark like a shield, and fades.
  final Interval? ring;

  /// A second, fainter ring.
  final Interval? echo;

  /// The mark moves up from the centre to make room for the name.
  final Interval? lift;

  /// "Baby Vax" rises in.
  final Interval? word;

  /// The tagline fades in.
  final Interval? tagline;

  /// Progress of [phase] at controller value [t]: 0 before, 1 after, and 1
  /// throughout when the phase does not play.
  static double at(Interval? phase, double t) =>
      phase == null ? 1 : phase.transform(t.clamp(0.0, 1.0));
}

/// Decides when the splash may leave: once its animation has finished (or
/// was skipped with a tap) **and** the app's start-up work is done. So the
/// splash never waits longer than the longer of the two.
class SplashGate {
  SplashGate({required this.onReady});

  /// Called exactly once, when both are done.
  final void Function() onReady;

  bool _animationDone = false;
  bool _initDone = false;
  bool _fired = false;

  bool get animationDone => _animationDone;
  bool get initDone => _initDone;
  bool get fired => _fired;

  void markAnimationDone() {
    _animationDone = true;
    _check();
  }

  void markInitDone() {
    _initDone = true;
    _check();
  }

  /// A tap: stop waiting for the animation (start-up work still finishes).
  void skip() => markAnimationDone();

  void _check() {
    if (_fired || !_animationDone || !_initDone) return;
    _fired = true;
    onReady();
  }
}
