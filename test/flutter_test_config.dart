import 'dart:async';

import 'helpers/pump_app.dart';

/// Runs before every test file: draws text with the app's real font (the
/// bundled Cairo) instead of the test font, whose glyphs are all 1em
/// squares, so widths, wrapping and overflow match a phone.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFont();
  await testMain();
}
