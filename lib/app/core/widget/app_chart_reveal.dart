import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Draws a chart in from its start (the left: chart axes run left to right
/// in both languages) over 300 ms, the first time it appears or when its
/// data set changes ([revealKey]) (polish §2.2). With "Remove animations"
/// on, the chart is simply there.
class AppChartReveal extends StatelessWidget {
  const AppChartReveal({super.key, required this.child, this.revealKey});

  final Widget child;

  /// Changing it plays the reveal again (a different metric or range).
  final Object? revealKey;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object?>(revealKey),
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.long,
      curve: AppMotion.enter,
      child: child,
      builder: (BuildContext context, double t, Widget? child) => ClipRect(
        clipper: _RevealClipper(t),
        child: Opacity(opacity: 0.4 + 0.6 * t, child: child),
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.t);

  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}
