import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The state actions for one dose.
///
///   Pending             -> "Mark as given", "Mark as skipped"
///   Completed / Skipped -> "Undo (mark as pending)"
class MedicalDateActions extends StatelessWidget {
  final bool canMarkCompleted;
  final bool canMarkSkipped;
  final bool canUndo;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkSkipped;
  final VoidCallback? onUndo;

  const MedicalDateActions({
    super.key,
    required this.canMarkCompleted,
    required this.canMarkSkipped,
    required this.canUndo,
    this.onMarkCompleted,
    this.onMarkSkipped,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canMarkCompleted)
          AppButton(
            key: const Key('mark_completed_button'),
            onPressed: onMarkCompleted,
            text: "MedicalDateActions_mark_completed".tr,
          ),
        if (canMarkSkipped) ...[
          12.sbh,
          TextButton(
            key: const Key('mark_skipped_button'),
            onPressed: onMarkSkipped,
            child: AppText(
              text: "MedicalDateActions_mark_skipped".tr,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (canUndo)
          AppButton(
            key: const Key('undo_button'),
            onPressed: onUndo,
            text: "MedicalDateActions_undo".tr,
          ),
      ],
    );
  }
}
