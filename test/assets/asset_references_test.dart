// Guards the asset bundle against two failure modes:
//
//  1. Code references an asset path that is not bundled (typo, file moved,
//     or pubspec.yaml not updated). That is a blank image or an exception
//     at runtime, found only on the screen that uses it.
//  2. pubspec.yaml bundles a file nothing uses, which ships dead weight to
//     every user.
//
// It reads the real AssetManifest that `flutter test` builds from pubspec.yaml,
// so it follows exactly the same rules as the app, then decodes every image
// and parses every Lottie file to prove each one still renders.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// Matches a string literal holding a path under assets/.
final _assetLiteral = RegExp(r'''['"](assets/[^'"\s$]+)['"]''');

const _imageExtensions = {'.png', '.webp', '.jpg', '.jpeg', '.gif'};

/// Every asset path written as a literal anywhere under lib/.
Map<String, List<String>> _assetPathsReferencedInCode() {
  final refs = <String, List<String>>{};
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in dartFiles) {
    for (final m in _assetLiteral.allMatches(file.readAsStringSync())) {
      refs.putIfAbsent(m.group(1)!, () => []).add(file.path);
    }
  }
  return refs;
}

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  return dot < 0 ? '' : path.substring(dot).toLowerCase();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> bundled;
  late Map<String, List<String>> referenced;

  setUpAll(() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    // Only this app's own assets; packages/ entries come from dependencies.
    bundled =
        manifest.listAssets().where((a) => a.startsWith('assets/')).toSet();
    referenced = _assetPathsReferencedInCode();
  });

  test('code references at least one asset (the scan itself works)', () {
    expect(referenced, isNotEmpty);
    expect(bundled, isNotEmpty);
  });

  test('every asset path referenced in lib/ is bundled by pubspec.yaml', () {
    final missing = {
      for (final e in referenced.entries)
        if (!bundled.contains(e.key)) e.key: e.value,
    };
    expect(
      missing,
      isEmpty,
      reason: 'Referenced in code but not bundled. Add it to the assets '
          'section of pubspec.yaml, or fix the path: $missing',
    );
  });

  test('every referenced asset exists on disk', () {
    final absent = referenced.keys.where((p) => !File(p).existsSync());
    expect(absent, isEmpty, reason: 'Missing files: ${absent.toList()}');
  });

  test('every bundled asset is referenced from lib/ (no dead weight)', () {
    final unused = bundled.difference(referenced.keys.toSet());
    expect(
      unused,
      isEmpty,
      reason: 'Bundled but never referenced in lib/. Remove it from '
          'pubspec.yaml, or reference it: $unused',
    );
  });

  test('every bundled image decodes', () async {
    final images =
        bundled.where((a) => _imageExtensions.contains(_extension(a)));
    expect(images, isNotEmpty);
    for (final path in images) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: path);
      expect(frame.image.height, greaterThan(0), reason: path);
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('every bundled Lottie animation parses and has frames', () async {
    final animations = bundled.where((a) => _extension(a) == '.json');
    expect(animations, isNotEmpty);
    for (final path in animations) {
      final data = await rootBundle.load(path);
      final composition = await LottieComposition.fromByteData(data);
      expect(composition.duration, greaterThan(Duration.zero), reason: path);
      expect(composition.bounds.width, greaterThan(0), reason: path);
      expect(composition.bounds.height, greaterThan(0), reason: path);
      // An image an animation needs must be embedded (data: URI) or bundled
      // next to it; otherwise it renders as a hole.
      final dir = path.substring(0, path.lastIndexOf('/') + 1);
      for (final image in composition.images.values) {
        final embedded = image.fileName.startsWith('data:');
        final external = '$dir${image.dirName}${image.fileName}';
        expect(embedded || bundled.contains(external), isTrue,
            reason: '$path needs image $external, which is not bundled');
      }
    }
  });
}
