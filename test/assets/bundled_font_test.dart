// The app's font must load from the bundle with runtime fetching off.
//
// If this fails, the app would silently fall back to the system font for
// every user, because configureBundledFonts() forbids the network download
// that used to hide a missing or misnamed font file.

import 'dart:io';

import 'package:baby_vax/app/config/themes/app_fonts.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// SHA-256 that google_fonts 9.0.0 pins for Cairo w400. The bundled file
/// must be exactly this one, or the app no longer renders as it did when the
/// font was fetched at runtime.
const _cairoRegularSha256 =
    'd33c4f55184435de6dd2689c7de5c584345f30f0c3e71aac1ba192a947539b00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureBundledFonts);

  test('runtime font fetching is disabled', () {
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('GoogleFonts.cairo() loads from the bundle without the network',
      () async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      final family = GoogleFonts.cairo().fontFamily;
      await GoogleFonts.pendingFonts();
      expect(family, 'Cairo_regular');
    } finally {
      FlutterError.onError = previous;
    }
    expect(errors, isEmpty,
        reason: 'google_fonts reported: ${errors.map((e) => e.exception)}');
  });

  test('the bundled Cairo is byte-for-byte the google_fonts file', () async {
    final data = await rootBundle.load('assets/google_fonts/Cairo-Regular.ttf');
    expect(sha256.convert(data.buffer.asUint8List()).toString(),
        _cairoRegularSha256);
  });

  test('the OFL licence ships with the font and is registered', () async {
    expect(File(cairoLicenseAsset).readAsStringSync(),
        contains('SIL OPEN FONT LICENSE Version 1.1'));
    final entries = await LicenseRegistry.licenses.toList();
    expect(entries.any((e) => e.packages.contains('Cairo font')), isTrue);
  });
}
