import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/app_logo.dart';
import 'package:baby_vax/app/modules/splash/splash_controller.dart';
import 'package:baby_vax/app/modules/splash/splash_timing.dart';
import 'package:flutter/services.dart';

/// The Flutter half of the splash, "protection bloom" (polish §3).
///
/// It starts exactly where the system splash stops: the same green, the
/// same mark at the same size and position (centred, 60×72 SVG units at
/// 5/3 dp each). Because the system splash already shows the whole mark,
/// the bloom plays *over* it instead of making it disappear first: a light
/// line traces the shield, a soft wave of light rises through it, a ring
/// ripples out like a shield and fades, then the mark lifts and "Baby Vax"
/// rises letter by letter with the tagline fading in. The mark then flies
/// into the first screen's logo.
///
/// Full on the first launch (2.4 s), short afterwards (0.8 s), a plain fade
/// with "Remove animations". A tap skips. Everything is painted from the
/// logo's vector paths by one [CustomPainter] driven by one controller: no
/// images, no layers per frame, nothing to rebuild while it plays.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  /// Size of one SVG unit in logical pixels; matches the native splash
  /// images (400×480 px at xxxhdpi for the 60×72 frame).
  static const double unit = 5 / 3;

  /// How far the mark rises to make room for the name.
  static const double lift = 56;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final SplashController controller = Get.find<SplashController>();
  AnimationController? _anim;
  late SplashMode _mode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_anim != null) return;
    _mode = SplashMode.of(
      firstLaunch: controller.firstLaunch,
      reduceMotion: AppMotion.reduced(context),
    );
    _anim = AnimationController(vsync: this, duration: _mode.duration)
      ..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) controller.onAnimationDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color background =
        dark ? AppPalette.splashDark : AppPalette.splashLight;
    final BrandMarkColors markColors =
        dark ? BrandMarkColors.onSplashDark : BrandMarkColors.onSplashLight;
    final Animation<double> anim = _anim!;
    final SplashPhases phases = _mode.phases;
    final double liftBy = _mode == SplashMode.reduced ? 0 : SplashView.lift;
    final Size markSize = Size(BrandMark.frame.width * SplashView.unit,
        BrandMark.frame.height * SplashView.unit);

    Widget mark = CustomPaint(
      size: markSize,
      painter: _BloomPainter(
        animation: anim,
        phases: phases,
        colors: markColors,
        glow: dark ? AppPalette.markShieldOnDark : AppPalette.n100,
      ),
    );
    if (_mode.sharedElement) {
      mark = Hero(
        tag: AppLogo.heroTag,
        flightShuttleBuilder: AppLogo.flightShuttle,
        child: mark,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        key: const Key('splash_skip'),
        behavior: HitTestBehavior.opaque,
        onTap: controller.skip,
        child: Semantics(
          label: 'Baby Vax',
          child: ColoredBox(
            color: background,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final Offset centre = Offset(c.maxWidth / 2, c.maxHeight / 2);
                return AnimatedBuilder(
                  animation: anim,
                  builder: (BuildContext context, Widget? _) {
                    final double t = anim.value;
                    final double up = liftBy *
                        AppMotion.emphasized
                            .transform(SplashPhases.at(phases.lift, t));
                    final double markTop = centre.dy - markSize.height / 2 - up;
                    return Stack(
                      children: <Widget>[
                        Positioned(
                          left: centre.dx - markSize.width / 2,
                          top: markTop,
                          child: mark,
                        ),
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          top: markTop + markSize.height + AppSpacing.lg,
                          child: _Words(
                              t: t, mode: _mode, phases: phases, dark: dark),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// "Baby Vax" and the tagline.
class _Words extends StatelessWidget {
  const _Words({
    required this.t,
    required this.mode,
    required this.phases,
    required this.dark,
  });

  final double t;
  final SplashMode mode;
  final SplashPhases phases;
  final bool dark;

  static const String name = 'Baby Vax'; // the brand name is never translated

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color ink = dark ? AppPalette.markShieldOnDark : AppPalette.n100;
    final TextStyle? nameStyle = text.displaySmall?.copyWith(color: ink);
    final double word = SplashPhases.at(phases.word, t);
    final double tagline =
        AppMotion.enter.transform(SplashPhases.at(phases.tagline, t));

    Widget wordmark;
    if (mode.letterByLetter) {
      // Each letter rises 12dp and fades in, 40% of the phase after the
      // one before it.
      const int n = name.length;
      wordmark = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          for (int i = 0; i < n; i++)
            Builder(builder: (BuildContext context) {
              final double start = i / n * 0.6;
              final double v = AppMotion.enter
                  .transform(((word - start) / 0.4).clamp(0.0, 1.0));
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - v)),
                  child: Text(name[i], style: nameStyle),
                ),
              );
            }),
        ],
      );
    } else {
      final double v = AppMotion.enter.transform(word);
      wordmark = Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, mode == SplashMode.reduced ? 0 : 8 * (1 - v)),
          child: Text(name, style: nameStyle, textDirection: TextDirection.ltr),
        ),
      );
    }

    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          wordmark,
          const SizedBox(height: AppSpacing.xs),
          Opacity(
            opacity: tagline,
            child: Text(
              "SplashView_tagline".tr,
              textAlign: TextAlign.center,
              style: text.bodyMedium
                  ?.copyWith(color: AppPalette.markLeafHighlight),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark plus the bloom: outline trace, rising wave and ripples. Repaints
/// from the animation directly, so nothing rebuilds per frame.
class _BloomPainter extends CustomPainter {
  _BloomPainter({
    required this.animation,
    required this.phases,
    required this.colors,
    required this.glow,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final SplashPhases phases;
  final BrandMarkColors colors;
  final Color glow;

  static Path? _outline;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = animation.value;
    final double s = size.width / BrandMark.frame.width;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(s)
      ..translate(-BrandMark.centre.dx, -BrandMark.centre.dy);

    // Ripples first, so they pass behind the mark.
    _ring(canvas, phases.ring, t, 0.55);
    _ring(canvas, phases.echo, t, 0.3);

    // A light line traces the shield's outline from the top, both ways.
    // Drawn under the mark, so it shows as a 2-unit rim around it.
    final Interval? outline = phases.outline;
    if (outline != null && t < outline.end + 0.15) {
      final double o = AppMotion.standard.transform(outline.transform(t));
      final double fade =
          t <= outline.end ? 1 : 1 - ((t - outline.end) / 0.15).clamp(0.0, 1.0);
      final Path path = _outline ??= BrandMark.shield;
      final Paint line = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = BrandMark.shieldStroke + 4
        ..strokeCap = StrokeCap.round
        ..color = colors.leafHighlight.withValues(alpha: 0.9 * fade);
      for (final ui.PathMetric m in path.computeMetrics()) {
        final double half = m.length / 2 * o;
        canvas
          ..drawPath(m.extractPath(0, half), line)
          ..drawPath(m.extractPath(m.length - half, m.length), line);
      }
    }
    BrandMark.paint(canvas, colors);

    // A soft wave of light rises through the shield, then fades.
    final Interval? wave = phases.wave;
    if (wave != null && t > wave.begin && t < wave.end) {
      final double w = wave.transform(t);
      final Rect b = BrandMark.shield.getBounds();
      final double level =
          b.bottom - (b.height + 6) * AppMotion.standard.transform(w);
      final double alpha = 0.35 * math.sin(math.pi * w);
      final Path water = Path()..moveTo(b.left - 2, level);
      for (double x = b.left - 2; x <= b.right + 2; x += 2) {
        water.lineTo(
            x, level + 1.6 * math.sin((x / b.width) * 2 * math.pi + w * 6));
      }
      water
        ..lineTo(b.right + 2, b.bottom + 2)
        ..lineTo(b.left - 2, b.bottom + 2)
        ..close();
      canvas
        ..save()
        ..clipPath(BrandMark.shield);
      canvas.drawPath(water, Paint()..color = glow.withValues(alpha: alpha));
      canvas.restore();
      // The leaf stays crisp above the light.
      BrandMark.paintLeaf(canvas, colors);
    }

    canvas.restore();
  }

  void _ring(Canvas canvas, Interval? phase, double t, double strength) {
    if (phase == null || t <= phase.begin || t >= phase.end) return;
    final double r = AppMotion.enter.transform(phase.transform(t));
    final double radius = 38 + 34 * r;
    canvas.drawCircle(
      BrandMark.centre,
      radius,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * (1 - r) + 0.4
        ..color = glow.withValues(alpha: strength * (1 - r)),
    );
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.colors != colors || old.phases != phases || old.glow != glow;
}
