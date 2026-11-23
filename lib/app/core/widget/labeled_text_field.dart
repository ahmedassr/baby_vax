import '../imports/import_manger.dart';

/// v1.0's labelled field, now a thin wrapper over [AppField].
///
/// Kept so screens can move to [AppField] one at a time; removed once the
/// last caller is gone.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.obscureText = false,
    this.onChanged,
    this.onTap,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppField(
        label: label.tr,
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        obscureText: obscureText,
        onChanged: onChanged,
        onTap: onTap,
        errorText: errorText,
      ),
    );
  }
}
