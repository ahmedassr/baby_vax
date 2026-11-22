import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';

import '../model/milestone_record.dart';
import 'milestone_bar.dart';

/// What the milestone sheet returns.
sealed class MilestoneSheetResult {
  const MilestoneSheetResult();
}

/// Save this record.
class SaveMilestone extends MilestoneSheetResult {
  const SaveMilestone(this.record);

  final MilestoneRecord record;
}

/// Remove what was recorded for the milestone.
class RemoveMilestone extends MilestoneSheetResult {
  const RemoveMilestone();
}

/// Record the day a milestone was achieved, with an optional note; or,
/// with [noteOnly], just the note for the doctor visit.
class MilestoneSheet extends StatefulWidget {
  const MilestoneSheet({
    super.key,
    required this.milestone,
    required this.today,
    this.initial,
    this.birthDate,
    this.noteOnly = false,
  });

  final MotorMilestone milestone;
  final DateTime today;

  /// What is recorded now, if anything.
  final MilestoneRecord? initial;

  /// The earliest date allowed.
  final DateTime? birthDate;

  /// Only the note (the details screen's "Add a note for the doctor
  /// visit"); the date stays as it is.
  final bool noteOnly;

  static Future<MilestoneSheetResult?> show({
    required MotorMilestone milestone,
    required DateTime today,
    MilestoneRecord? initial,
    DateTime? birthDate,
    bool noteOnly = false,
  }) =>
      AppSheet.show<MilestoneSheetResult>(MilestoneSheet(
        milestone: milestone,
        today: today,
        initial: initial,
        birthDate: birthDate,
        noteOnly: noteOnly,
      ));

  /// Whether [d] is allowed: not before the birth date, not after today.
  static bool dateAllowed(DateTime d, DateTime today, DateTime? birthDate) {
    final DateTime day = DateTime(d.year, d.month, d.day);
    final DateTime last = DateTime(today.year, today.month, today.day);
    if (day.isAfter(last)) return false;
    if (birthDate == null) return true;
    return !day
        .isBefore(DateTime(birthDate.year, birthDate.month, birthDate.day));
  }

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  late DateTime _date = widget.initial?.achievedAt ?? widget.today;
  late final TextEditingController _dateText =
      TextEditingController(text: AppDateFormat.date(_date));
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  String? _dateError;

  @override
  void dispose() {
    _dateText.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime first = widget.birthDate ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : _date,
      firstDate: first,
      lastDate: widget.today,
      helpText: "Milestone_date".tr,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = AppDateFormat.date(picked);
      _dateError = null;
    });
  }

  void _save() {
    final String note = _note.text.trim();
    if (!widget.noteOnly &&
        !MilestoneSheet.dateAllowed(_date, widget.today, widget.birthDate)) {
      setState(() => _dateError = "Milestone_date_error".tr);
      return;
    }
    Navigator.of(context).pop(SaveMilestone(MilestoneRecord(
      milestone: widget.milestone,
      achievedAt: widget.noteOnly ? widget.initial?.achievedAt : _date,
      note: note.isEmpty ? null : note,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canRemove =
        !widget.noteOnly && (widget.initial?.achieved ?? false);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: AppSpacing.sheet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                  widget.noteOnly
                      ? "Milestone_note_title".tr
                      : MilestoneText.name(widget.milestone),
                  key: const Key('milestone_sheet_title'),
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
                widget.noteOnly
                    ? MilestoneText.name(widget.milestone)
                    : MilestoneText.criteria(widget.milestone),
                key: const Key('milestone_sheet_criteria'),
                style: theme.textTheme.bodyMedium),
            if (!widget.noteOnly) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppField(
                key: const Key('milestone_date'),
                label: "Milestone_date".tr,
                controller: _dateText,
                readOnly: true,
                onTap: _pickDate,
                helper: "Milestone_date_rule".tr,
                errorText: _dateError,
                suffixIcon: const Icon(Icons.calendar_today_rounded),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('milestone_note'),
              label: "Record_note".tr,
              optional: true,
              controller: _note,
              maxLength: MilestoneRecord.maxNote,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('milestone_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              key: const Key('milestone_cancel'),
              text: "cancel".tr,
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (canRemove) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('milestone_remove'),
                text: "Milestone_remove".tr,
                icon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () =>
                    Navigator.of(context).pop(const RemoveMilestone()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
