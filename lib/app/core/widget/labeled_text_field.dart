import '../imports/import_manger.dart';

class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? errorText;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label.tr,
          style: AppTextStyles.bodyLarge,
          maxLines: 2,
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
        ),
        8.sbh,
      ],
    );
  }
}
