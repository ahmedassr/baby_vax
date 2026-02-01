import '../imports/import_manger.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool obscureText;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? errorText;
  final double? fontSize;
  final double? borderRadius;
  final TextStyle? labelStyle;

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
    this.fontSize,
    this.borderRadius,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label.tr,
          style: AppTextStyles.bodyMedium.copyWith(fontSize: fontSize),
          maxLines: 3,
        ),
        8.sbh,
        AppTextField(
          controller: controller,
          keyboardType: keyboardType,
          fillColor: context.theme.scaffoldBackgroundColor,
          readOnly: readOnly,
          onChanged: (value) => onChanged?.call(value),
          onTap: onTap,
          errorText: errorText,
          radius: borderRadius,
          obscureText: obscureText,
          labelStyle: labelStyle,
        ),
        8.sbh,
      ],
    );
  }
}
