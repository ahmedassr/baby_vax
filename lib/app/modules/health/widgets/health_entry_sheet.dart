import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';
import 'package:baby_vax/app/core/utils/validators.dart';

import '../model/health_entry.dart';
import 'health_labels.dart';

/// What the entry sheet returns.
sealed class HealthSheetResult {
  const HealthSheetResult();
}

class SaveHealthEntry extends HealthSheetResult {
  const SaveHealthEntry(this.entry);

  final HealthEntry entry;
}

class DeleteHealthEntry extends HealthSheetResult {
  const DeleteHealthEntry();
}

/// Add or edit one Health log entry of [kind]: a temperature (with how it
/// was taken), signs (picked from a list), a medicine given (name and the
/// amount as the parent writes it — no advice), or a note; with its date
/// and time. Shows WHO's message for what is entered as it is entered.
class HealthEntrySheet extends StatefulWidget {
  const HealthEntrySheet({
    super.key,
    required this.kind,
    required this.now,
    this.initial,
    this.birthDate,
    this.doseId,
    this.onLearnMore,
  });

  final HealthEntryKind kind;
  final DateTime now;
  final HealthEntry? initial;

  /// For WHO's young-infant figures (up to 2 months).
  final DateTime? birthDate;

  /// Links a new entry to a vaccine dose (from the after-vaccination card).
  final String? doseId;

  /// Opens "When to get medical help".
  final VoidCallback? onLearnMore;

  static Future<HealthSheetResult?> show({
    required HealthEntryKind kind,
    required DateTime now,
    HealthEntry? initial,
    DateTime? birthDate,
    String? doseId,
    VoidCallback? onLearnMore,
  }) =>
      AppSheet.show<HealthSheetResult>(HealthEntrySheet(
        kind: initial?.kind ?? kind,
        now: now,
        initial: initial,
        birthDate: birthDate,
        doseId: doseId,
        onLearnMore: onLearnMore,
      ));

  @override
  State<HealthEntrySheet> createState() => _HealthEntrySheetState();
}

class _HealthEntrySheetState extends State<HealthEntrySheet> {
  late DateTime _at = widget.initial?.at ?? widget.now;
  late final TextEditingController _date =
      TextEditingController(text: AppDateFormat.date(_at));
  late final TextEditingController _time =
      TextEditingController(text: AppDateFormat.time(_at));
  late final TextEditingController _temp = TextEditingController(
      text: widget.initial?.tempC?.toStringAsFixed(1) ?? '');
  late TemperatureMethod _method =
      widget.initial?.method ?? TemperatureMethod.armpit;
  late final Set<HealthSymptom> _symptoms = Set<HealthSymptom>.of(
      widget.initial?.symptoms ?? const <HealthSymptom>[]);
  late final TextEditingController _medicine =
      TextEditingController(text: widget.initial?.medicine ?? '');
  late final TextEditingController _amount =
      TextEditingController(text: widget.initial?.amount ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  String? _error;

  HealthEntryKind get kind => widget.kind;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _date,
      _time,
      _temp,
      _medicine,
      _amount,
      _note
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAt(DateTime at) => setState(() {
        _at = at;
        _date.text = AppDateFormat.date(at);
        _time.text = AppDateFormat.time(at);
        _error = null;
      });

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _at.isAfter(widget.now) ? widget.now : _at,
      firstDate: widget.birthDate ?? DateTime(widget.now.year - 5),
      lastDate: widget.now,
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

  double? get _tempValue => Validators.parseDecimal(_temp.text);

  /// The entry as it stands in the form.
  HealthEntry get _entry => HealthEntry(
        id: widget.initial?.id,
        kind: kind,
        at: _at,
        tempC: kind == HealthEntryKind.temperature ? _tempValue : null,
        method: kind == HealthEntryKind.temperature ? _method : null,
        symptoms: kind == HealthEntryKind.symptoms
            ? <HealthSymptom>[
                for (final HealthSymptom s in HealthLabels.symptomOrder)
                  if (_symptoms.contains(s)) s
              ]
            : const <HealthSymptom>[],
        medicine: kind == HealthEntryKind.medicine ? _medicine.text : null,
        amount: kind == HealthEntryKind.medicine ? _amount.text : null,
        note: _note.text,
        doseId: widget.initial?.doseId ?? widget.doseId,
      );

  CareLevel get _care {
    final bool young = HealthGuidance.isYoungInfant(widget.birthDate, _at);
    return switch (kind) {
      HealthEntryKind.temperature => _tempValue == null ||
              _tempValue! < HealthEntry.minTempC ||
              _tempValue! > HealthEntry.maxTempC
          ? CareLevel.none
          : HealthGuidance.forTemperature(_tempValue!, _method,
              youngInfant: young),
      HealthEntryKind.symptoms =>
        HealthGuidance.forSymptoms(_symptoms, youngInfant: young),
      _ => CareLevel.none,
    };
  }

  void _save() {
    final HealthEntry e = _entry;
    String? error;
    if (_at.isAfter(widget.now.add(const Duration(minutes: 1)))) {
      error = "Health_future_error".tr;
    } else if (!e.isComplete) {
      error = switch (kind) {
        HealthEntryKind.temperature => "Health_temp_error".tr,
        HealthEntryKind.symptoms => "Health_symptoms_error".tr,
        HealthEntryKind.medicine => "Health_medicine_error".tr,
        HealthEntryKind.note => "Health_note_error".tr,
      };
    }
    setState(() => _error = error);
    if (error != null) return;
    Navigator.of(context).pop(SaveHealthEntry(e));
  }

  String get _title => widget.initial != null
      ? "Health_edit_title".tr
      : "Health_add_${kind.name}".tr;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
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
              child: Text(_title, style: theme.textTheme.titleLarge),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppBanner(
                  key: const Key('health_form_error'),
                  tone: AppBannerTone.error,
                  message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            ..._kindFields(theme, scheme),
            const SizedBox(height: AppSpacing.md),
            CareMessage(level: _care, onLearnMore: widget.onLearnMore),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: AppField(
                    key: const Key('health_date'),
                    label: "Reminders_date".tr,
                    controller: _date,
                    readOnly: true,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppField(
                    key: const Key('health_time'),
                    label: "Reminders_time".tr,
                    controller: _time,
                    readOnly: true,
                    onTap: _pickTime,
                    suffixIcon: const Icon(Icons.schedule_rounded, size: 20),
                  ),
                ),
              ],
            ),
            if (kind != HealthEntryKind.note) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppField(
                key: const Key('health_note'),
                label: "Record_note".tr,
                optional: true,
                controller: _note,
                maxLength: HealthEntry.maxNote,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const MedicalDisclaimer(compact: true),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              key: const Key('health_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            if (widget.initial != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('health_delete'),
                text: "Health_delete".tr,
                icon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () =>
                    Navigator.of(context).pop(const DeleteHealthEntry()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _kindFields(ThemeData theme, ColorScheme scheme) {
    switch (kind) {
      case HealthEntryKind.temperature:
        final bool? fever = _tempValue == null
            ? null
            : HealthGuidance.isFever(_tempValue!, _method);
        return <Widget>[
          AppField(
            key: const Key('health_temp'),
            label: "Health_temp_label".tr,
            controller: _temp,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffixText: '°C',
            helper: "Health_temp_helper".tr,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("Health_method_label".tr, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceGroup<TemperatureMethod>(
            selected: _method,
            onSelected: (m) => setState(() => _method = m),
            options: <AppChoiceOption<TemperatureMethod>>[
              for (final (TemperatureMethod m, IconData icon)
                  in <(TemperatureMethod, IconData)>[
                (TemperatureMethod.armpit, Icons.accessibility_new_rounded),
                (TemperatureMethod.rectal, Icons.child_friendly_rounded),
                (TemperatureMethod.other, Icons.device_thermostat_rounded),
              ])
                AppChoiceOption<TemperatureMethod>(
                  key: Key('health_method_${m.name}'),
                  value: m,
                  label: HealthLabels.method(m),
                  icon: icon,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _method == TemperatureMethod.other
                ? "Health_method_other_hint".tr
                : "Health_method_hint".tr,
            key: const Key('health_method_hint'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (fever == true) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text("Health_fever_label".tr,
                key: const Key('health_fever'),
                style: theme.textTheme.titleSmall),
          ],
        ];
      case HealthEntryKind.symptoms:
        return <Widget>[
          Text("Health_symptoms_hint".tr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          AppListGroup(children: <Widget>[
            for (final HealthSymptom s in HealthLabels.symptomOrder)
              CheckboxListTile(
                key: Key('health_symptom_${s.name}'),
                value: _symptoms.contains(s),
                title: Text(HealthLabels.symptom(s),
                    style: theme.textTheme.bodyLarge),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? v) => setState(() {
                  v == true ? _symptoms.add(s) : _symptoms.remove(s);
                  _error = null;
                }),
              ),
          ]),
        ];
      case HealthEntryKind.medicine:
        return <Widget>[
          AppField(
            key: const Key('health_medicine'),
            label: "Health_medicine_label".tr,
            controller: _medicine,
            maxLength: HealthEntry.maxMedicine,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.md),
          AppField(
            key: const Key('health_amount'),
            label: "Health_amount_label".tr,
            optional: true,
            controller: _amount,
            maxLength: HealthEntry.maxAmount,
            helper: "Health_amount_helper".tr,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppBanner(
            key: const Key('health_no_advice'),
            message: "Health_medicine_no_advice".tr,
          ),
        ];
      case HealthEntryKind.note:
        return <Widget>[
          AppField(
            key: const Key('health_note'),
            label: "Record_note".tr,
            controller: _note,
            maxLength: HealthEntry.maxNote,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _error = null),
          ),
        ];
    }
  }
}
