import 'package:baby_vax/app/config/constant/app_colors.dart';
import 'package:baby_vax/app/config/themes/app_text_style.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String?>? onSaved;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? hintText;
  final String? label;
  final Color? fillColor;
  final double? radius;

  const AppTextField(
      {super.key,
      required this.controller,
      this.readOnly = false,
      this.onTap,
      this.onChanged,
      this.onSaved,
      this.keyboardType,
      this.errorText,
      this.hintText,
      this.label,
      this.fillColor,
      this.radius});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        errorText: errorText,
        errorMaxLines: 2,
        hintText: hintText,
        hintStyle: AppTextStyles.bodySmall.copyWith(
            color:
                context.isDarkMode ? AppColors.greyDark : AppColors.greyMedium),
        labelText: label,
        labelStyle: AppTextStyles.headLineMedium.copyWith(
            color:
                context.isDarkMode ? AppColors.textWhite : AppColors.textBlack),
        fillColor: fillColor ??
            (context.isDarkMode
                ? AppColors.backgroundDark
                : AppColors.backgroundLight),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? 20),
            borderSide: BorderSide(
                color: context.isDarkMode
                    ? AppColors.greyMedium
                    : AppColors.greyDark)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius ?? 20),
            borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? 20),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius ?? 20),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}
