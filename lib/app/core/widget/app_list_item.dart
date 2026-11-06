import '../imports/import_manger.dart';

class AppListItem extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hideLeadingIcon;
  final bool hideTrailingIcon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget title;
  final Widget? subTitle;
  final VoidCallback? onTrailingTap;

  const AppListItem(
      {super.key,
      required this.title,
      this.subTitle,
      this.padding,
      this.onTap,
      this.leadingIcon,
      this.trailingIcon,
      this.hideLeadingIcon = false,
      this.hideTrailingIcon = false,
      this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? AppSpacing.listItemPadding,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          shape: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Colors.transparent, width: 0)),
          tileColor: context.isDarkMode
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.white,
          contentPadding: AppSpacing.listItemPadding,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.9),
            radius: 24,
            child: hideLeadingIcon
                ? null
                : Icon(
                    leadingIcon,
                    color: Colors.white,
                  ),
          ),
          title: title,
          subtitle: subTitle,
          trailing: hideTrailingIcon
              ? null
              : GestureDetector(
                  onTap: onTrailingTap, child: Icon(trailingIcon)),
        ),
      ),
    );
  }
}
