import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:flutter/services.dart';

/// The app's top bar: flat, on the scaffold colour, centred title, with a
/// standard 48dp back button that mirrors in RTL and is labelled for
/// TalkBack.
///
/// v1.0's back button was a `CircleAvatar` of radius `20.r` inside a
/// `24.w` box — about 24dp, half the minimum touch target — with
/// `Colors.grey.shade200` hard-coded behind it in dark mode too.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final double fontSize;
  final bool showBackButton;
  final List<Widget>? action;
  final VoidCallback? onBackPressed;

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

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.action,
    this.onBackPressed,
    this.titleMaxLines,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? base = theme.textTheme.titleLarge;
    final bool canPop =
        showBackButton && (ModalRoute.of(context)?.canPop ?? false);

    return AppBar(
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      leading: canPop || onBackPressed != null
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              // arrow_back_rounded has matchTextDirection, so it points the
              // right way in Arabic.
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBackPressed ?? Get.back,
            )
          : null,
      title: title == null
          ? null
          : titleMaxLines == null
              ? Text(
                  title!,
                  style: base?.copyWith(fontSize: fontSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : MediaQuery.withClampedTextScaling(
                  maxScaleFactor: wrappedTitleMaxTextScale,
                  child: Text(
                    title!,
                    style: base?.copyWith(
                      fontSize: fontSize,
                      height: wrappedTitleLineHeight,
                    ),
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
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
