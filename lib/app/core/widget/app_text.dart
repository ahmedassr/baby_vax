import '../imports/import_manger.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final FontWeight fontWeight;
  final double fontSize;
  final Color? color;
  final double? height;
  final int? maxLines;
  final TextAlign textAlign;
  final TextOverflow overflow;

  const AppText({
    required this.text,
    this.style,
    this.fontWeight = FontWeight.w600,
    this.fontSize = 14.0,
    this.color,
    this.height,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      softWrap: true,
      style: style ??
          AppTextStyles.bodyMedium.copyWith(
            fontWeight: fontWeight,
            fontSize: fontSize,
            color: color ??
                (context.isDarkMode ? AppColors.textWhite : AppColors.textBlack),
            height: height,
          ),
    );
  }
}
