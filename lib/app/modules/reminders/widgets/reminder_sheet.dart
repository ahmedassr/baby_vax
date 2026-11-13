import 'package:baby_vax/app/core/imports/import_manger.dart';

import '../model/reminder_model.dart';

/// What the reminder sheet returns.
sealed class ReminderSheetResult {
  const ReminderSheetResult();
}

/// Save this reminder.
class SaveReminder extends ReminderSheetResult {
  const SaveReminder(this.reminder);

  final ReminderModel reminder;
}

/// Delete the reminder being edited.
class DeleteReminder extends ReminderSheetResult {
  const DeleteReminder();
}

/// Add or edit a reminder: title (with a few quick picks), date, time,
/// repeat and a note.
class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key, required this.now, this.initial});

  final DateTime now;
  final ReminderModel? initial;

  /// Quick titles. Plain labels for common reminders, not advice.
  static const List<String> suggestionKeys = <String>[
    "Reminders_suggest_doctor",
    "Reminders_suggest_vitamin_d",
    "Reminders_suggest_follow_up",
  ];

  static Future<ReminderSheetResult?> show(
          {required DateTime now, ReminderModel? initial}) =>
      Get.bottomSheet<ReminderSheetResult>(
          ReminderSheet(now: now, initial: initial),
          isScrollControlled: true);

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  late DateTime _at = widget.initial?.dateTime ??
      DateTime(widget.now.year, widget.now.month, widget.now.day + 1, 9);
  late ReminderRepeat _repeat = widget.initial?.repeat ?? ReminderRepeat.none;
  late final TextEditingController _date =
      TextEditingController(text: AppDateFormat.date(_at));
  late final TextEditingController _time =
      TextEditingController(text: AppDateFormat.time(_at));
  String? _titleError;
  String? _whenError;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _title,
      _note,
      _date,
      _time
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAt(DateTime at) => setState(() {
        _at = at;
        _date.text = AppDateFormat.date(at);
        _time.text = AppDateFormat.time(at);
        _whenError = null;
      });

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _at.isBefore(widget.now) ? widget.now : _at,
      firstDate: DateTime(widget.now.year - 1),
      lastDate: DateTime(widget.now.year + 5),
      helpText: "Reminders_date".tr,
    );
    if (d != null) {
      _setAt(DateTime(d.year, d.month, d.day, _at.hour, _at.minute));
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
      helpText: "Reminders_time".tr,
    );
    if (t != null) {
      _setAt(DateTime(_at.year, _at.month, _at.day, t.hour, t.minute));
    }
  }

  void _save() {
    final String title = _title.text.trim();
    _titleError = title.isEmpty ? "Reminders_title_required".tr : null;
    // A one-off in the past would never fire.
    _whenError = _repeat == ReminderRepeat.none && !_at.isAfter(widget.now)
        ? "Reminders_past_error".tr
        : null;
    setState(() {});
    if (_titleError != null || _whenError != null) return;
    Navigator.of(context).pop(SaveReminder(ReminderModel(
      id: widget.initial?.id,
      title: title,
      dateTime: _at,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      repeat: _repeat,
      enabled: widget.initial?.enabled ?? true,
    )));
  }

  static String repeatLabel(ReminderRepeat r) => switch (r) {
        ReminderRepeat.none => "Reminders_repeat_none".tr,
        ReminderRepeat.daily => "Reminders_repeat_daily".tr,
        ReminderRepeat.weekly => "Reminders_repeat_weekly".tr,
        ReminderRepeat.monthly => "Reminders_repeat_monthly".tr,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
                  widget.initial == null
                      ? "Reminders_add_title".tr
                      : "Reminders_edit_title".tr,
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('reminder_title'),
              label: "Reminders_title_label".tr,
              controller: _title,
              maxLength: ReminderModel.maxTitle,
              textCapitalization: TextCapitalization.sentences,
              errorText: _titleError,
              onChanged: (_) => setState(() => _titleError = null),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String k in ReminderSheet.suggestionKeys)
                  ActionChip(
                    label: Text(k.tr),
                    onPressed: () => setState(() {
                      _title.text = k.tr;
                      _titleError = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppField(
                    key: const Key('reminder_date'),
                    label: "Reminders_date".tr,
                    controller: _date,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppField(
                    key: const Key('reminder_time'),
                    label: "Reminders_time".tr,
                    controller: _time,
                    readOnly: true,
                    onTap: _pickTime,
                    suffixIcon: const Icon(Icons.schedule_rounded, size: 20),
                  ),
                ),
              ],
            ),
            if (_whenError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(_whenError!,
                    key: const Key('reminder_when_error'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text("Reminders_repeat".tr, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final List<ReminderRepeat> row in <List<ReminderRepeat>>[
              <ReminderRepeat>[ReminderRepeat.none, ReminderRepeat.daily],
              <ReminderRepeat>[ReminderRepeat.weekly, ReminderRepeat.monthly],
            ]) ...<Widget>[
              Row(
                children: <Widget>[
                  for (final ReminderRepeat r in row) ...<Widget>[
                    if (r != row.first) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppChoiceTile(
                        key: Key('reminder_repeat_${r.name}'),
                        label: repeatLabel(r),
                        icon: r == ReminderRepeat.none
                            ? Icons.looks_one_outlined
                            : Icons.repeat_rounded,
                        selected: _repeat == r,
                        onTap: () => setState(() {
                          _repeat = r;
                          _whenError = null;
                        }),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppField(
              key: const Key('reminder_note'),
              label: "Record_note".tr,
              optional: true,
              controller: _note,
              maxLength: ReminderModel.maxNote,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('reminder_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            if (widget.initial != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('reminder_delete'),
                text: "Reminders_delete".tr,
                icon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () =>
                    Navigator.of(context).pop(const DeleteReminder()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
