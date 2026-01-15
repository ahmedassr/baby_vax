import 'package:baby_vax/app/core/imports/import_manger.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final double? radius;
  final double? minWidth;
  final double? minHeight;

  const AppButton(
      {super.key,
      required this.text,
      this.onPressed,
      this.color,
      this.radius,
      this.minWidth,
      this.minHeight});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            elevation: 0.3,
            minimumSize: Size(minWidth ?? double.infinity, minHeight ?? 50),
            backgroundColor: color ?? AppColors.secondPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius ?? 20))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: AppText(
            text: text,
            style: AppTextStyles.headLineSmall
                .copyWith(color: AppColors.primary, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
