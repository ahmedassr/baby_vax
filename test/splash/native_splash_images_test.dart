// Renders the native splash images from the same vector paths the Flutter
// splash draws, so the hand-over matches to the pixel (polish §3.1).
//
// Skipped unless NATIVE_SPLASH_OUT is set:
//
//   NATIVE_SPLASH_OUT=assets/branding/png \
//     flutter test test/splash/native_splash_images_test.dart
//   dart run flutter_native_splash:create

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter_test/flutter_test.dart';

final String? out = Platform.environment['NATIVE_SPLASH_OUT'];

/// Draws the mark centred on (54, 54) into a [px]-square or 400×480 canvas
/// at [unitPx] pixels per SVG unit.
Future<void> render(String name, BrandMarkColors colors,
    {required int width, required int height, required double unitPx}) async {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  final Canvas canvas = Canvas(rec);
  canvas
    ..translate(width / 2, height / 2)
    ..scale(unitPx)
    ..translate(-BrandMark.centre.dx, -BrandMark.centre.dy);
  BrandMark.paint(canvas, colors);
  final ui.Image img = await rec.endRecording().toImage(width, height);
  final ByteData? png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('$out/$name').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('writes the native splash images', skip: out == null, () async {
    // Pre-Android-12: the 60×72 frame at xxxhdpi (4 px per dp), 5/3 dp per
    // unit, so 400×480 px. Android 12+: a 288dp (1152 px) icon, same scale.
    const double unitPx = 4 * 5 / 3;
    for (final (String suffix, BrandMarkColors c)
        in <(String, BrandMarkColors)>[
      ('', BrandMarkColors.onSplashLight),
      ('-dark', BrandMarkColors.onSplashDark),
    ]) {
      await render('splash-legacy$suffix.png', c,
          width: 400, height: 480, unitPx: unitPx);
      await render('splash-android12$suffix.png', c,
          width: 1152, height: 1152, unitPx: unitPx);
    }
  });

  test('the Android 12 icon fits inside the 192dp safe circle', () {
    // Furthest point of the shield (with its stroke) from the centre, in dp.
    final Rect b = BrandMark.shieldBounds;
    double far = 0;
    for (final Offset p in <Offset>[
      b.topLeft,
      b.topRight,
      b.bottomLeft,
      b.bottomRight
    ]) {
      far = far > (p - BrandMark.centre).distance
          ? far
          : (p - BrandMark.centre).distance;
    }
    expect(far * 5 / 3, lessThan(96));
  });
}
