import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The state actions for one dose.
///
///   Pending             -> "Mark as given" (primary), "Mark as skipped"
///                          (danger outline)
///   Completed / Skipped -> "Undo (mark as pending)" (outline)
class MedicalDateActions extends StatelessWidget {
  final bool canMarkCompleted;
  final bool canMarkSkipped;
  final bool canUndo;
  final bool busy;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkSkipped;
  final VoidCallback? onUndo;

  const MedicalDateActions({
    super.key,
    required this.canMarkCompleted,
    required this.canMarkSkipped,
    required this.canUndo,
    this.busy = false,
    this.onMarkCompleted,
    this.onMarkSkipped,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (canMarkCompleted)
          AppButton(
            key: const Key('mark_completed_button'),
            onPressed: onMarkCompleted,
            loading: busy,
            icon: Icons.check_rounded,
            text: "MedicalDateActions_mark_completed".tr,
          ),
        if (canMarkSkipped) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('mark_skipped_button'),
            onPressed: busy ? null : onMarkSkipped,
            variant: AppButtonVariant.danger,
            text: "MedicalDateActions_mark_skipped".tr,
          ),
        ],
        if (canUndo)
          AppButton(
            key: const Key('undo_button'),
            onPressed: onUndo,
            loading: busy,
            icon: Icons.undo_rounded,
            variant: AppButtonVariant.outline,
            text: "MedicalDateActions_undo".tr,
          ),
      ],
    );
  }
}
