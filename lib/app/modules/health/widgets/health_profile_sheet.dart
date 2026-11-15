import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The child's health profile: allergies, long-term conditions, blood type
/// and an emergency contact. All optional, free text as the parent writes
/// it. Shown in the Health tab and on the vaccination card. Pops with the
/// updated profile, or null when dismissed.
class HealthProfileSheet extends StatefulWidget {
  const HealthProfileSheet({super.key, required this.user});

  final UserModel user;

  static const int maxText = 300;
  static const int maxContact = 100;

  static Future<UserModel?> show(UserModel user) =>
      AppSheet.show<UserModel>(HealthProfileSheet(user: user));

  @override
  State<HealthProfileSheet> createState() => _HealthProfileSheetState();
}

class _HealthProfileSheetState extends State<HealthProfileSheet> {
  late final TextEditingController _allergies =
      TextEditingController(text: widget.user.allergies ?? '');
  late final TextEditingController _conditions =
      TextEditingController(text: widget.user.conditions ?? '');
  late final TextEditingController _contact =
      TextEditingController(text: widget.user.emergencyContact ?? '');
  late String? _bloodType = widget.user.bloodType;

  @override
  void dispose() {
    _allergies.dispose();
    _conditions.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(widget.user.withHealth(
        allergies: _allergies.text,
        conditions: _conditions.text,
        bloodType: _bloodType,
        emergencyContact: _contact.text,
      ));

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
            Text("Health_profile_hint".tr, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('health_allergies'),
              label: "Health_allergies".tr,
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
              optional: true,
              controller: _conditions,
              maxLength: HealthProfileSheet.maxText,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            Text("Health_blood_type".tr, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String? b in <String?>[
                  ...UserModel.bloodTypes,
                  null,
                ])
                  ChoiceChip(
                    key: Key('health_blood_${b ?? 'unknown'}'),
                    label: Text(b == null
                        ? "Health_blood_unknown".tr
                        // Blood types read left to right in both languages.
                        : bidiIsolate(b)),
                    selected: _bloodType == b,
                    onSelected: (_) => setState(() => _bloodType = b),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppField(
              key: const Key('health_contact'),
              label: "Health_emergency".tr,
              optional: true,
              controller: _contact,
              maxLength: HealthProfileSheet.maxContact,
              helper: "Health_emergency_helper".tr,
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
