import 'package:auto_size_text/auto_size_text.dart';
import 'package:baby_vax/app/config/themes/app_text_style.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';

class KeyValueRichText extends StatelessWidget {
  final Color? textColor;
  final String label;
  final String value;
  final double? labelFontSize;
  final double? valueFontSize;
  final TextAlign? textAlign;

  const KeyValueRichText(
      {super.key,
      required this.label,
      required this.value,
      this.textColor,
      this.labelFontSize,
      this.valueFontSize,
      this.textAlign});

  @override
  Widget build(BuildContext context) {
    return AutoSizeText.rich(
      TextSpan(
        children: [
          TextSpan(
              text: "$label:",
              style: AppTextStyles.bodyMedium
                  .copyWith(fontSize: labelFontSize, color: textColor)),
          TextSpan(
              text: value,
              style: AppTextStyles.captionLarge
                  .copyWith(fontSize: labelFontSize, color: textColor))
        ],
      ),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: 5,
    );
  }
}
