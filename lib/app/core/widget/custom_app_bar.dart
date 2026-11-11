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

  /// When set, the title wraps to at most this many lines and ends with an
  /// ellipsis, and the bar grows so every line is fully visible. When null
  /// the bar keeps the standard height.
  final int? titleMaxLines;

  /// Line height of a wrapping title. Fixed, because the bundled Cairo font's
  /// own line height is almost twice its size.
  static const double wrappedTitleLineHeight = 1.25;

  /// Largest text scale a wrapping title follows, so [preferredSize] (which
  /// cannot see the device setting) always leaves room for it.
  static const double wrappedTitleMaxTextScale = 1.3;

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
      this.titleMaxLines,
      this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: context.theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      surfaceTintColor: context.theme.scaffoldBackgroundColor,
      elevation: elevation,
      toolbarHeight: preferredSize.height,
      title: title == null
          ? null
          : titleMaxLines == null
              ? AppText(
                  text: title ?? "",
                  style:
                      AppTextStyles.headLineSmall.copyWith(fontSize: fontSize),
                  maxLines: 3,
                )
              : MediaQuery.withClampedTextScaling(
                  maxScaleFactor: wrappedTitleMaxTextScale,
                  child: AppText(
                    text: title!,
                    style: AppTextStyles.headLineSmall.copyWith(
                      fontSize: fontSize,
                      height: wrappedTitleLineHeight,
                    ),
                    maxLines: titleMaxLines,
                    textAlign: TextAlign.center,
                  ),
                ),
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
  Size get preferredSize {
    final int? lines = titleMaxLines;
    if (title == null || lines == null) {
      return const Size.fromHeight(kToolbarHeight);
    }
    final double text =
        lines * fontSize * wrappedTitleLineHeight * wrappedTitleMaxTextScale;
    return Size.fromHeight(
        text + 16 > kToolbarHeight ? text + 16 : kToolbarHeight);
  }
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
