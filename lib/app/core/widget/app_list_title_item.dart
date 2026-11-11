import 'package:baby_vax/app/core/imports/import_manger.dart';

class AppListTitleItem extends StatelessWidget {
  final String? title;
  final String? additionalTitle;
  final IconData? icon;
  final Color? iconColor;
  final double borderRadius;
  final double iconSize;
  final VoidCallback? onTap;

  const AppListTitleItem(
      {super.key,
      this.title,
      this.additionalTitle,
      this.icon,
      this.iconColor,
      this.borderRadius = 8,
      this.iconSize = 24,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: AppBoxDecoration.decoration(
            context: context, borderRadius: borderRadius),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppColors.primary,
              )
            ],
            16.sbw,
            Expanded(
              child: AppText(
                text: title ?? "",
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: context.isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            if (additionalTitle != null) ...[
              20.sbw,
              AppText(
                text: additionalTitle ?? "",
                style:
                    AppTextStyles.boldSmall.copyWith(color: AppColors.textHint),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
