import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/widget/back_icon.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final double fontSize;
  final bool showBackButton;
  final List<Widget>? action;
  final Widget? customLeading;
  final VoidCallback? onBackPressed;
  final double elevation;
  final Color? background;
  final Color? foreground;

  const CustomAppBar(
      {super.key,
      this.title,
      this.showBackButton = true,
      this.action,
      this.customLeading,
      this.onBackPressed,
      this.background,
      this.foreground,
      this.elevation = 0,
      this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: context.theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      surfaceTintColor: context.theme.scaffoldBackgroundColor,
      elevation: elevation,
      title: title != null
          ? AppText(
              text: title ?? "",
              style: AppTextStyles.headLineSmall.copyWith(fontSize: fontSize),
              maxLines: 3,
            )
          : null,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      backgroundColor: background ?? Colors.transparent,
      foregroundColor: foreground,
      leadingWidth: 48.w,
      leading: _buildLeadingWidget(
          size: 24.0,
          showBackButton: showBackButton,
          customLeading: customLeading,
          onBackPressed: onBackPressed),
      actions: action,
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

Widget _buildLeadingWidget(
    {required double size,
    required bool showBackButton,
    required VoidCallback? onBackPressed,
    required Widget? customLeading}) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: customLeading ??
        (showBackButton
            ? _buildDefaultBackButton(onBackPressed, size: size)
            : null),
  );
}

Widget _buildDefaultBackButton(VoidCallback? onBackPressed,
    {required double size}) {
  return SizedBox(
    width: size.w,
    height: size.h,
    child: BackIcon(
      onTap: onBackPressed ?? Get.back,
    ),
  );
}
