import 'dart:math' as math;

import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A calm circular progress indicator with the count in the middle: how many
/// of the schedule's doses are behind the parent.
///
/// Deliberately not a percentage — "7 of 10" is how a parent counts doses —
/// and deliberately green only for the done part, with a neutral track, so
/// it reads as progress rather than as a warning.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.done,
    required this.total,
    this.size = 88,
    this.strokeWidth = 8,
  });

  final int done;
  final int total;
  final double size;
  final double strokeWidth;

  /// Fraction complete, 0 when there is nothing to do.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Semantics(
      label: "progress_semantic_label"
          .trParams({'done': '$done', 'total': '$total'}),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            fraction: fraction,
            track: scheme.surfaceContainerHigh,
            fill: scheme.primary,
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + AppSpacing.xs),
                child: Text.rich(
                  TextSpan(children: <InlineSpan>[
                    TextSpan(text: '$done', style: theme.textTheme.titleLarge),
                    TextSpan(text: '/$total', style: theme.textTheme.bodySmall),
                  ]),
                  // Digits read left to right in both languages.
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.fill,
    required this.strokeWidth,
  });

  final double fraction;
  final Color track;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arc = rect.deflate(strokeWidth / 2);
    final Paint base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arc, 0, 2 * math.pi, false, base);
    if (fraction <= 0) return;
    final Paint done = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arc, -math.pi / 2, 2 * math.pi * fraction, false, done);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}
