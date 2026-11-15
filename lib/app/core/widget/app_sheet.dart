import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Opens every bottom sheet in the app.
///
/// Uses Flutter's own `showModalBottomSheet`, so the sheet takes its look
/// entirely from the theme's `bottomSheetTheme`: an opaque surface in light
/// and dark, rounded top corners, the drag handle and the scrim behind it.
///
/// `Get.bottomSheet` is not used: get 4.7.3 passes
/// `backgroundColor: Colors.transparent` unless told otherwise, which
/// overrides the theme and let the screen behind show through every sheet
/// (the phone review found "No reminders yet" visible behind the reminder
/// form). It also draws no drag handle. A guard test keeps it out.
class AppSheet {
  const AppSheet._();

  /// Shows [sheet] over the current screen and returns what it pops with.
  ///
  /// Always scroll-controlled (the sheets hold forms that must move above
  /// the keyboard) and kept below the status bar.
  static Future<T?> show<T>(Widget sheet, {BuildContext? context}) {
    final BuildContext? ctx = context ?? Get.overlayContext ?? Get.context;
    if (ctx == null) return Future<T?>.value();
    return showModalBottomSheet<T>(
      context: ctx,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => sheet,
    );
  }
}
