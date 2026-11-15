import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The child's health profile: blood type, allergies, long-term conditions
/// and an emergency contact (name, relation to the child, phone). All
/// optional. Shown in the Health tab and on the vaccination card. Pops with
/// the updated profile, or null when dismissed.
class HealthProfileSheet extends StatefulWidget {
  const HealthProfileSheet({super.key, required this.user});

  final UserModel user;

  static const int maxText = 300;

  static Future<UserModel?> show(UserModel user) =>
      AppSheet.show<UserModel>(HealthProfileSheet(user: user));

  /// The contact for [name], [phone] and [relation], or the message for the
  /// field that is wrong. Both blank clears the contact.
  static ({EmergencyContact? contact, String? nameError, String? phoneError})
      contactFrom(String name, String phone, String? relation) {
    final String n = name.trim();
    final String p = phone.trim();
    if (n.isEmpty && p.isEmpty) {
      return (contact: null, nameError: null, phoneError: null);
    }
    final String? normalized =
        p.isEmpty ? null : EmergencyContact.normalizePhone(p);
    final String? nameError =
        n.isEmpty ? "Health_contact_name_needed".tr : null;
    final String? phoneError = p.isEmpty
        ? "Health_contact_phone_needed".tr
        : normalized == null
            ? "Health_contact_phone_invalid".tr
            : null;
    if (nameError != null || phoneError != null) {
      return (contact: null, nameError: nameError, phoneError: phoneError);
    }
    return (
      contact:
          EmergencyContact(name: n, phone: normalized!, relation: relation),
      nameError: null,
      phoneError: null,
    );
  }

  @override
  State<HealthProfileSheet> createState() => _HealthProfileSheetState();
}

class _HealthProfileSheetState extends State<HealthProfileSheet> {
  late final TextEditingController _allergies =
      TextEditingController(text: widget.user.allergies ?? '');
  late final TextEditingController _conditions =
      TextEditingController(text: widget.user.conditions ?? '');
  late final TextEditingController _name =
      TextEditingController(text: widget.user.emergencyContact?.name ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.emergencyContact?.phone ?? '');
  late String? _bloodType = widget.user.bloodType;
  late String? _relation = widget.user.emergencyContact?.relation;
  String? _nameError;
  String? _phoneError;

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final r =
        HealthProfileSheet.contactFrom(_name.text, _phone.text, _relation);
    if (r.nameError != null || r.phoneError != null) {
      setState(() {
        _nameError = r.nameError;
        _phoneError = r.phoneError;
      });
      return;
    }
    Navigator.of(context).pop(widget.user.withHealth(
      allergies: _allergies.text,
      conditions: _conditions.text,
      bloodType: _bloodType,
      emergencyContact: r.contact,
    ));
  }

  Widget _section(ThemeData theme, IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ),
          ],
        ),
      );

  Widget _chips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required String Function(T) key,
    required ValueChanged<T> onSelected,
  }) =>
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final T v in values)
            ChoiceChip(
              key: Key(key(v)),
              label: Text(label(v)),
              selected: selected == v,
              onSelected: (_) => onSelected(v),
            ),
        ],
      );

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
              child: Text("Health_profile_title".tr,
                  style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text("Health_profile_hint".tr,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),

            // ---- medical ------------------------------------------------
            _section(theme, Icons.medical_information_outlined,
                "Health_profile_medical".tr),
            Text("Health_blood_type".tr, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _chips<String?>(
              values: <String?>[...UserModel.bloodTypes, null],
              selected: _bloodType,
              key: (b) => 'health_blood_${b ?? 'unknown'}',
              // Blood types read left to right in both languages.
              label: (b) =>
                  b == null ? "Health_blood_unknown".tr : bidiIsolate(b),
              onSelected: (b) => setState(() => _bloodType = b),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('health_allergies'),
              label: "Health_allergies".tr,
              hint: "Health_allergies_hint".tr,
              optional: true,
              controller: _allergies,
              maxLength: HealthProfileSheet.maxText,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            AppField(
              key: const Key('health_conditions'),
              label: "Health_conditions".tr,
              hint: "Health_conditions_hint".tr,
              optional: true,
              controller: _conditions,
              maxLength: HealthProfileSheet.maxText,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ---- emergency contact -------------------------------------
            _section(
                theme, Icons.contact_phone_outlined, "Health_emergency".tr),
            AppField(
              key: const Key('health_contact_name'),
              label: "Health_contact_name".tr,
              controller: _name,
              errorText: _nameError,
              maxLength: EmergencyContact.maxName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.name],
              prefixIcon: Icons.person_outline_rounded,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text("Health_contact_relation".tr,
                style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _chips<String?>(
              values: EmergencyContact.relations,
              selected: _relation,
              key: (r) => 'health_relation_$r',
              label: (r) => "Health_relation_$r".tr,
              // Tapping the chosen one again clears it.
              onSelected: (r) =>
                  setState(() => _relation = _relation == r ? null : r),
            ),
            const SizedBox(height: AppSpacing.md),
            AppField(
              key: const Key('health_contact_phone'),
              label: "Health_contact_phone".tr,
              hint: "Health_contact_phone_hint".tr,
              controller: _phone,
              errorText: _phoneError,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              autofillHints: const <String>[AutofillHints.telephoneNumber],
              prefixIcon: Icons.call_outlined,
              maxLength: 24,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('health_profile_save'),
              text: "Record_save".tr,
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
