import 'package:flutter/widgets.dart';

/// Icons the app draws differently from Material's defaults.
class AppIcons {
  const AppIcons._();

  /// "Show chart" without mirroring. Material marks the chart icons to flip
  /// in right-to-left layouts, which in Arabic turned the rising Growth
  /// line into a falling one; the app's growth charts run left to right in
  /// both languages, so the icon does too (polish §2.3).
  static const IconData growth = IconData(0xf0174, fontFamily: 'MaterialIcons');
}
