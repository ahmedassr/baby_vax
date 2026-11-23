import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The colours of one rendering of the Baby Vax mark.
@immutable
class BrandMarkColors {
  const BrandMarkColors({
    required this.shield,
    required this.leaf,
    required this.leafHighlight,
    required this.vein,
  });

  /// The mark as in `assets/branding/logo.svg`: green shield, white leaf.
  static const BrandMarkColors standard = BrandMarkColors(
    shield: AppPalette.markShield,
    leaf: AppPalette.markLeafLight,
    leafHighlight: AppPalette.n100,
    vein: AppPalette.markShield,
  );

  /// On the light splash green: light shield, green leaf.
  static const BrandMarkColors onSplashLight = BrandMarkColors(
    shield: AppPalette.markShieldOnLight,
    leaf: AppPalette.markLeaf,
    leafHighlight: AppPalette.markLeafHighlight,
    vein: AppPalette.markVein,
  );

  /// On the dark splash green: the shield a touch dimmer.
  static const BrandMarkColors onSplashDark = BrandMarkColors(
    shield: AppPalette.markShieldOnDark,
    leaf: AppPalette.markLeaf,
    leafHighlight: AppPalette.markLeafHighlight,
    vein: AppPalette.markVein,
  );

  final Color shield;
  final Color leaf;
  final Color leafHighlight;
  final Color vein;

  static BrandMarkColors lerp(BrandMarkColors a, BrandMarkColors b, double t) =>
      BrandMarkColors(
        shield: Color.lerp(a.shield, b.shield, t)!,
        leaf: Color.lerp(a.leaf, b.leaf, t)!,
        leafHighlight: Color.lerp(a.leafHighlight, b.leafHighlight, t)!,
        vein: Color.lerp(a.vein, b.vein, t)!,
      );
}

/// The Baby Vax mark as vector paths, from `assets/branding/logo.svg`, so
/// the splash can draw, trace and fill it instead of loading an image.
///
/// Coordinates are the SVG's: the mark is centred on (54, 54) and the
/// [frame] (x 24–84, y 18–90, 60×72 units) is the area `app_logo.webp` and
/// the native splash images cover.
class BrandMark {
  const BrandMark._();

  /// The artwork's frame, in SVG units.
  static const Rect frame = Rect.fromLTWH(24, 18, 60, 72);

  /// The centre the native splash images are centred on.
  static const Offset centre = Offset(54, 54);

  static const double shieldStroke = 4;
  static const double veinStroke = 2.2;

  static final Path shield = Path()
    ..moveTo(54, 22)
    ..cubicTo(62.5, 27.5, 71, 29.5, 79, 29.5)
    ..lineTo(79, 51)
    ..cubicTo(79, 68.5, 68.5, 80.5, 54, 87)
    ..cubicTo(39.5, 80.5, 29, 68.5, 29, 51)
    ..lineTo(29, 29.5)
    ..cubicTo(37, 29.5, 45.5, 27.5, 54, 22)
    ..close();

  static final Path leaf = Path()
    ..moveTo(41, 70)
    ..cubicTo(40, 51.5, 50.5, 40, 69, 38.5)
    ..cubicTo(70, 57, 59, 68.5, 41, 70)
    ..close();

  static final Path leafHighlight = Path()
    ..moveTo(41, 70)
    ..cubicTo(40, 51.5, 50.5, 40, 69, 38.5)
    ..cubicTo(58, 47, 48.5, 57.5, 41, 70)
    ..close();

  static final Path vein = Path()
    ..moveTo(43.5, 67.5)
    ..cubicTo(50, 58, 57.5, 50, 66.5, 41.5);

  /// Outer bounds of the shield including its stroke, in SVG units.
  static Rect get shieldBounds => shield.getBounds().inflate(shieldStroke / 2);

  /// Paints the whole mark in SVG units (scale the canvas first).
  static void paint(Canvas canvas, BrandMarkColors c, {double opacity = 1}) {
    Paint fill(Color color) => Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: color.a * opacity);
    canvas.drawPath(shield, fill(c.shield));
    canvas.drawPath(
        shield,
        fill(c.shield)
          ..style = PaintingStyle.stroke
          ..strokeWidth = shieldStroke
          ..strokeJoin = StrokeJoin.round);
    paintLeaf(canvas, c, opacity: opacity);
  }

  /// Paints only the leaf and its vein.
  static void paintLeaf(Canvas canvas, BrandMarkColors c,
      {double opacity = 1}) {
    Paint fill(Color color) => Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: color.a * opacity);
    canvas.drawPath(leaf, fill(c.leaf));
    canvas.drawPath(leafHighlight, fill(c.leafHighlight));
    canvas.drawPath(
        vein,
        fill(c.vein)
          ..style = PaintingStyle.stroke
          ..strokeWidth = veinStroke
          ..strokeCap = StrokeCap.round);
  }
}

/// Paints the mark, filling its box the way `app_logo.webp` fills an
/// [AppLogo] (the [BrandMark.frame] scaled to fit, centred).
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter(this.colors);

  final BrandMarkColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width / BrandMark.frame.width,
        size.height / BrandMark.frame.height);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(s)
      ..translate(-BrandMark.centre.dx, -BrandMark.centre.dy);
    BrandMark.paint(canvas, colors);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) => old.colors != colors;
}
