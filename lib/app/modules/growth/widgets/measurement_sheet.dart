import 'dart:async';

import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/growth/growth_percentile.dart';
import 'package:baby_vax/app/core/utils/validators.dart';

import '../model/measurement_model.dart';

/// What the measurement sheet returns.
sealed class MeasurementSheetResult {
  const MeasurementSheetResult();
}

/// Save this measurement.
class SaveMeasurement extends MeasurementSheetResult {
  const SaveMeasurement(this.measurement);

  final MeasurementModel measurement;
}

/// Delete the measurement being edited.
class DeleteMeasurement extends MeasurementSheetResult {
  const DeleteMeasurement();
}

/// Add or edit one dated measurement: date, weight, height, head
/// circumference (any of them) and a note.
class MeasurementSheet extends StatefulWidget {
  const MeasurementSheet({
    super.key,
    required this.today,
    this.initial,
    this.birthDate,
    this.sex,
    this.confirmUnusual = askUnusual,
  });

  final DateTime today;

  /// The measurement being edited; null to add one.
  final MeasurementModel? initial;

  /// The earliest date allowed, and the age the WHO check is made at.
  final DateTime? birthDate;

  /// 'female' / 'male' / null, for the WHO check.
  final String? sex;

  /// Asks "Are you sure?" with [message]; true saves anyway.
  final Future<bool> Function(String message) confirmUnusual;

  /// The app's own question dialog: "Save anyway" / "Check again".
  static Future<bool> askUnusual(String message) async {
    final Completer<bool> yes = Completer<bool>();
    await AppConstant.alertService.showAlert(AlertModel.yesOrNo(
      title: "Growth_unusual_title".tr,
      message: message,
      yesButtonText: "Growth_unusual_save".tr,
      noButtonText: "Growth_unusual_check".tr,
      yesAction: () => yes.complete(true),
      noAction: () => yes.complete(false),
    ));
    if (!yes.isCompleted) yes.complete(false);
    return yes.future;
  }

  /// The question for the first value far outside the WHO range for the
  /// baby's age and sex (below the 0.1st or above the 99.9th percentile),
  /// or null when every value is within it or cannot be checked.
  static String? unusualMessage({
    required Map<GrowthMetric, double?> values,
    required DateTime date,
    required DateTime? birthDate,
    required String? sex,
  }) {
    if (birthDate == null) return null;
    final double age = GrowthReference.ageInMonths(birthDate, date);
    for (final GrowthMetric m in GrowthMetric.values) {
      final double? v = values[m];
      if (v == null) continue;
      final UnusualValue? u = GrowthReference.unusual(
          metric: m, sex: sex, ageMonths: age, value: v);
      if (u == null || u == UnusualValue.none) continue;
      final String unit =
          m == GrowthMetric.weight ? "unit_kg".tr : "unit_cm".tr;
      return "Growth_unusual_${u.name}_${m.name}".trParams(<String, String>{
        'value': v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v',
        'unit': unit,
      });
    }
    return null;
  }

  static Future<MeasurementSheetResult?> show({
    required DateTime today,
    MeasurementModel? initial,
    DateTime? birthDate,
    String? sex,
  }) =>
      AppSheet.show<MeasurementSheetResult>(
        MeasurementSheet(
            today: today, initial: initial, birthDate: birthDate, sex: sex),
      );

  @override
  State<MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends State<MeasurementSheet> {
  late DateTime _date = widget.initial?.date ?? widget.today;
  late final TextEditingController _dateText =
      TextEditingController(text: AppDateFormat.date(_date));
  late final Map<GrowthMetric, TextEditingController> _values =
      <GrowthMetric, TextEditingController>{
    for (final GrowthMetric m in GrowthMetric.values)
      m: TextEditingController(text: _fmt(widget.initial?.valueOf(m))),
  };
  late final TextEditingController _note =
      TextEditingController(text: widget.initial?.note ?? '');
  final Map<GrowthMetric, String?> _errors = <GrowthMetric, String?>{};
  String? _formError;

  static String _fmt(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  @override
  void dispose() {
    _dateText.dispose();
    _note.dispose();
    for (final TextEditingController c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.birthDate ?? DateTime(2000),
      lastDate: widget.today,
      helpText: "Growth_date".tr,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateText.text = AppDateFormat.date(picked);
    });
  }

  Future<void> _save() async {
    final Map<GrowthMetric, double?> parsed = <GrowthMetric, double?>{};
    bool ok = true;
    for (final GrowthMetric m in GrowthMetric.values) {
      final String text = _values[m]!.text;
      _errors[m] = Validators.optionalMeasurement(text,
          min: m.bounds.min, max: m.bounds.max);
      if (_errors[m] != null) ok = false;
      parsed[m] = text.trim().isEmpty ? null : Validators.parseDecimal(text);
    }
    _formError = ok && parsed.values.every((v) => v == null)
        ? "Growth_need_one_value".tr
        : null;
    setState(() {});
    if (!ok || _formError != null) return;
    final String? unusual = MeasurementSheet.unusualMessage(
        values: parsed,
        date: _date,
        birthDate: widget.birthDate,
        sex: widget.sex);
    // Far outside the WHO range is more likely a typo or a unit mistake
    // than a real value: ask, but never refuse.
    if (unusual != null && !await widget.confirmUnusual(unusual)) return;
    if (!mounted) return;
    Navigator.of(context).pop(SaveMeasurement(MeasurementModel(
      id: widget.initial?.id,
      date: _date,
      weightKg: parsed[GrowthMetric.weight],
      heightCm: parsed[GrowthMetric.height],
      headCm: parsed[GrowthMetric.head],
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const TextInputType decimal =
        TextInputType.numberWithOptions(decimal: true);
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
                      ? "Growth_add_title".tr
                      : "Growth_edit_title".tr,
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text("Growth_sheet_hint".tr, style: theme.textTheme.bodySmall),
            if (_formError != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppBanner(
                  key: const Key('growth_form_error'),
                  tone: AppBannerTone.error,
                  message: _formError!),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('growth_date'),
              label: "Growth_date".tr,
              controller: _dateText,
              readOnly: true,
              onTap: _pickDate,
            ),
            for (final (GrowthMetric m, String label, String unit)
                in <(GrowthMetric, String, String)>[
              (GrowthMetric.weight, "weight_label".tr, "unit_kg".tr),
              (GrowthMetric.height, "height_label".tr, "unit_cm".tr),
              (GrowthMetric.head, "head_size_label".tr, "unit_cm".tr),
            ]) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppField(
                key: Key('growth_${m.name}'),
                label: label,
                optional: true,
                controller: _values[m]!,
                keyboardType: decimal,
                textInputAction: TextInputAction.next,
                suffixText: unit,
                errorText: _errors[m],
                onChanged: (_) => setState(() {
                  _errors[m] = null;
                  _formError = null;
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('growth_note'),
              label: "Record_note".tr,
              optional: true,
              controller: _note,
              maxLength: MeasurementModel.maxNote,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('growth_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            if (widget.initial != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('growth_delete'),
                text: "Growth_delete".tr,
                icon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () =>
                    Navigator.of(context).pop(const DeleteMeasurement()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
