import 'package:baby_vax/app/core/imports/import_library.dart';

class AppBoxDecoration {
  static BoxDecoration decoration(
      {required BuildContext context,
      double borderRadius = 8.0,
      double showOpacity = 8.0,
      double spearedRadius = 1.0,
      double blurRadius = 6.0,
      Offset shadowOffset = const Offset(0, 4),
      Color? color,
      BorderSide? borderSide,
      Color? shadowColor}) {
    return BoxDecoration(
        color: color ?? (context.isDarkMode ? Colors.black : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderSide != null
            ? Border.all(color: borderSide.color, width: borderSide.width)
            : null,
        boxShadow: [
          if (!context.isDarkMode)
            BoxShadow(
                color: shadowColor ?? Colors.grey.withValues(alpha: 0.5),
                blurRadius: blurRadius,
                spreadRadius: spearedRadius,
                offset: shadowOffset)
        ]);
  }
}
