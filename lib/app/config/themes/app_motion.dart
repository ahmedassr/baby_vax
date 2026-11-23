import 'package:flutter/material.dart';

/// The app's motion tokens (polish §2.2).
///
/// Every transition is short (150–300 ms) and uses the Material 3 standard
/// easing curves. Anything that moves reads its duration through [of], which
/// returns zero when the phone's "Remove animations" setting is on
/// (`MediaQuery.disableAnimations`), so the state still changes but nothing
/// slides or fades.
class AppMotion {
  const AppMotion._();

  /// 150 ms: small state changes (a chip, a check mark, a colour).
  static const Duration short = Duration(milliseconds: 150);

  /// 200 ms: content swaps (loading to content, step to step).
  static const Duration medium = Duration(milliseconds: 200);

  /// 300 ms: page transitions, sheets, a chart drawing itself.
  static const Duration long = Duration(milliseconds: 300);

  /// Page transitions.
  static const Duration page = long;

  /// For elements moving within the screen.
  static const Curve standard = Easing.standard;

  /// For elements entering the screen.
  static const Curve enter = Easing.standardDecelerate;

  /// For elements leaving the screen.
  static const Curve exit = Easing.standardAccelerate;

  /// For the one hero movement on a screen (the splash logo).
  static const Curve emphasized = Easing.emphasizedDecelerate;

  /// An [AnimatedSwitcher] layout that keeps content at the top, for
  /// swapping whole scrollable bodies (the default centres them).
  static Widget topLayout(Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, if (current != null) current],
      );

  /// Whether the user asked the system to remove animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when animations are removed.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
