
import 'package:baby_vax/app/config/constant/app_colors.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/widget/app_list_item.dart';

class AppDismissibleListItem extends StatelessWidget {
  final bool disableDismiss;
  final Widget title;
  final Widget? subTitle;
  final IconData? leadingIcon;
  final bool hideLeadingIcon;
  final bool hideTrailingIcon;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingTap;
  final Future<bool> Function()? onDelete;

  const AppDismissibleListItem(
      {super.key,
      this.disableDismiss = false,
      required this.title,
      this.subTitle,
      this.leadingIcon,
      this.hideLeadingIcon = false,
      this.hideTrailingIcon = false,
      this.onTap,
      this.onTrailingTap,
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    final appListItem = AppListItem(
      title: title,
      subTitle: subTitle,
      onTap: onTap,
      hideLeadingIcon: hideLeadingIcon,
      hideTrailingIcon: hideTrailingIcon,
      leadingIcon: leadingIcon,
      trailingIcon: Icons.more_horiz,
      onTrailingTap: onTrailingTap,
    );
    if (disableDismiss) {
      return appListItem;
    }
    return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.delete,
            color: AppColors.error,
            size: 30,
          ),
        ),
        onDismissed: (direction) => onDelete?.call(),
        confirmDismiss: (direction) async {
          if (onDelete != null) {
            return await onDelete!();
          }
          return true;
        },
        child: appListItem);
  }
}
