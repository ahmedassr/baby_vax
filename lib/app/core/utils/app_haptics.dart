import 'package:flutter/services.dart';

/// The app's haptic vocabulary: two kinds of feedback, used sparingly.
///
/// Haptics on every tap train people to ignore them. These fire only where a
/// physical "click" helps confirm something happened without looking: a
/// selection changing, and a record being saved.
class AppHaptics {
  const AppHaptics._();

  /// A selection changed: a filter chip, a stepper step, a tab.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Something was recorded: a dose marked as given, an undo, a save.
  static Future<void> confirm() => HapticFeedback.mediumImpact();
}
