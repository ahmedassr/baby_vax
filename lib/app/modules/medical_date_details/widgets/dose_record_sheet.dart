import 'package:baby_vax/app/core/imports/import_manger.dart';

/// "Record this dose": date given, clinic, batch/lot, note. All optional.
///
/// Pops with the [DoseRecord] to save — empty when the parent chose to mark
/// the dose as given without details — or null when dismissed, in which
/// case nothing changes.
class DoseRecordSheet extends StatefulWidget {
  const DoseRecordSheet({
    super.key,
    required this.initial,
    required this.today,
    this.editing = false,
  });

  final DoseRecord initial;
  final DateTime today;

  /// Editing the record of a dose already marked as given: no "without
  /// details" shortcut.
  final bool editing;

  /// Opens the sheet and returns what to save, or null if dismissed.
  static Future<DoseRecord?> show({
    required DoseRecord initial,
    required DateTime today,
    bool editing = false,
  }) {
    return Get.bottomSheet<DoseRecord>(
      DoseRecordSheet(initial: initial, today: today, editing: editing),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  @override
  State<DoseRecordSheet> createState() => _DoseRecordSheetState();
}

class _DoseRecordSheetState extends State<DoseRecordSheet> {
  late DateTime _given = widget.initial.givenDate ?? widget.today;
  late final TextEditingController _date =
      TextEditingController(text: AppDateFormat.date(_given));
  late final TextEditingController _clinic =
      TextEditingController(text: widget.initial.clinic ?? '');
  late final TextEditingController _lot =
      TextEditingController(text: widget.initial.lot ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.initial.note ?? '');

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _date,
      _clinic,
      _lot,
      _note
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _given,
      firstDate: DateTime(2000),
      // A dose cannot have been given in the future.
      lastDate: widget.today,
      helpText: "Record_given_date".tr,
    );
    if (picked == null) return;
    setState(() {
      _given = picked;
      _date.text = AppDateFormat.date(picked);
    });
  }

  void _save() => Navigator.of(context).pop(DoseRecord(
        givenDate: _given,
        clinic: _clinic.text,
        lot: _lot.text,
        note: _note.text,
      ).normalised());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      // Lift above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: AppSpacing.sheet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text("Record_sheet_title".tr,
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text("Record_sheet_hint".tr, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xl),
            AppField(
              key: const Key('record_date'),
              label: "Record_given_date".tr,
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('record_clinic'),
              label: "Record_clinic".tr,
              optional: true,
              controller: _clinic,
              maxLength: DoseRecord.maxClinic,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('record_lot'),
              label: "Record_lot".tr,
              optional: true,
              hint: "Record_lot_hint".tr,
              controller: _lot,
              maxLength: DoseRecord.maxLot,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('record_note'),
              label: "Record_note".tr,
              optional: true,
              controller: _note,
              maxLength: DoseRecord.maxNote,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('record_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            if (!widget.editing) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('record_without_details'),
                onPressed: () => Navigator.of(context).pop(const DoseRecord()),
                child: Text("Record_skip_details".tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
