import 'package:auto_size_text/auto_size_text.dart';
import 'package:baby_vax/app/config/themes/app_text_style.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

class KeyValueRichText extends StatelessWidget {
  final Color? textColor;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;
  final String? label;
  final String? value;
  final double? labelFontSize;
  final double? valueFontSize;
  final TextAlign? textAlign;

  const KeyValueRichText(
      {super.key,
       this.label,
      this.value,
      this.textColor,
      this.labelTextStyle,
      this.labelFontSize,
      this.valueTextStyle,
      this.valueFontSize,
      this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText.rich(
      TextSpan(
        children: [
          if(label != null)
          TextSpan(
              text: label,
              style: labelTextStyle ?? AppTextStyles.bodyMedium
                  .copyWith(fontSize: labelFontSize, color: textColor,)),
          if(value != null)
          TextSpan(
              text: value,
              style: valueTextStyle ?? AppTextStyles.captionLarge
                  .copyWith(fontSize: labelFontSize, color: textColor))
        ],
      ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
    );
  }
}
