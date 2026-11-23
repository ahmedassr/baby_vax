import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_motion.dart';

/// The page transition (polish §2.2): a Material shared-axis move along the
/// reading direction. The new page fades in while sliding 24dp in from the
/// end side (from the right in English, from the left in Arabic); the old
/// page fades out and moves 24dp towards the start. 300 ms in total, with
/// the standard decelerate / accelerate curves.
///
/// With "Remove animations" on, pages simply appear.
Widget buildAppPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (AppMotion.reduced(context)) return child;
  final double dir =
      Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
  const double distance = 24;

  final Animation<double> enterFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1, curve: AppMotion.enter),
      reverseCurve: const Interval(0.3, 1, curve: AppMotion.exit));
  final Animation<double> enterMove = CurvedAnimation(
      parent: animation, curve: AppMotion.enter, reverseCurve: AppMotion.exit);
  final Animation<double> exitFade = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, 0.35, curve: AppMotion.exit),
      reverseCurve: const Interval(0, 0.35, curve: AppMotion.enter));
  final Animation<double> exitMove = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.exit,
      reverseCurve: AppMotion.enter);

  return AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[animation, secondaryAnimation]),
    child: child,
    builder: (BuildContext context, Widget? child) {
      final double dx = dir * distance * (1 - enterMove.value) -
          dir * distance * exitMove.value;
      final double opacity =
          (enterFade.value * (1 - exitFade.value)).clamp(0.0, 1.0);
      return Opacity(
        opacity: opacity,
        child: Transform.translate(offset: Offset(dx, 0), child: child),
      );
    },
  );
}

/// [buildAppPageTransition] for routes built by Flutter itself (the licence
/// page, dialogs pushed as pages).
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      buildAppPageTransition(context, animation, secondaryAnimation, child);
}

/// [buildAppPageTransition] for GetX routes. GetX ignores the theme's
/// `pageTransitionsTheme` (it builds its own default), so `GetMaterialApp`
/// is given this as its `customTransition`.
class AppPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      buildAppPageTransition(context, animation, secondaryAnimation, child);
}
