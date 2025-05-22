import 'package:baby_vax/app/core/imports/import_manger.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final double? radius;

  const AppButton(
      {super.key, required this.onPressed, required this.text, this.radius});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius ?? 20))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: AppText(text: text,style: AppTextStyles.headLineSmall.copyWith(color: AppColors.backgroundLight,fontSize: 22),),
      ),
    );
  }
}
