import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A dose's status as a small pill: completed, pending, overdue or skipped.
///
/// Each status has its own icon as well as its own colour, so the chip does
/// not rely on colour alone (WCAG 1.4.1) — a parent with red-green colour
/// blindness can still tell "completed" from "overdue".
///
/// Replaces v1.0's `MedicalDateStatusBadge`, which had no overdue state and
/// set `fontSize: 11` inline.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.status, this.dense = false});

  final DoseDisplayStatus status;

  /// Smaller padding, for use inside a list row.
  final bool dense;

  /// The icon that accompanies [status].
  static IconData iconFor(DoseDisplayStatus status) => switch (status) {
        DoseDisplayStatus.completed => Icons.check_circle_rounded,
        DoseDisplayStatus.pending => Icons.schedule_rounded,
        DoseDisplayStatus.overdue => Icons.error_rounded,
        DoseDisplayStatus.skipped => Icons.remove_circle_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final pair = AppStatusColors.of(context).forStatus(status);
    final TextStyle? style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: pair.foreground);
    final String label = status.translationKey.tr;

    return Semantics(
      label: "status_semantic_label".trParams({'status': label}),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.md,
          vertical: dense ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(iconFor(status), size: 14, color: pair.foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
