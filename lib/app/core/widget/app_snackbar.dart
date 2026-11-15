import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The kind of an [AppSnackbar] message.
enum AppSnackbarTone { success, error, info }

/// Short feedback after an action: "Profile saved.", "Saved on this phone",
/// "Couldn't open settings".
///
/// The one way the app shows a snackbar or toast (phone review R4: the
/// profile screen used get's plain default bar). A leading icon and the
/// same theme colours as [AppBanner]'s tones, so the kind is never carried
/// by colour alone; rounded and floating. It is shown through the app's
/// ScaffoldMessenger, so it lands in the visible screen's Scaffold, which
/// lifts a floating snackbar above its navigation bar and FAB instead of
/// covering them.
///
/// Dialogs stay for what needs an answer or an acknowledgement (confirm a
/// delete, account deleted); inline [AppBanner]s for state that lasts
/// (offline, notifications off).
class AppSnackbar {
  const AppSnackbar._();

  static void success(String message, {BuildContext? context}) =>
      show(message, tone: AppSnackbarTone.success, context: context);

  static void error(String message, {BuildContext? context}) =>
      show(message, tone: AppSnackbarTone.error, context: context);

  static void info(String message, {BuildContext? context}) =>
      show(message, tone: AppSnackbarTone.info, context: context);

  /// Replaces any snackbar already showing with [message].
  static void show(
    String message, {
    AppSnackbarTone tone = AppSnackbarTone.info,
    BuildContext? context,
  }) {
    final BuildContext? ctx = context ?? Get.context;
    if (ctx == null) return;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(build(ctx, message, tone));
  }

  /// Background, text/icon colour and icon for [tone], from [scheme].
  static (Color, Color, IconData) styleFor(
          ColorScheme scheme, AppSnackbarTone tone) =>
      switch (tone) {
        AppSnackbarTone.success => (
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
            Icons.check_circle_rounded
          ),
        AppSnackbarTone.error => (
            scheme.errorContainer,
            scheme.onErrorContainer,
            Icons.error_rounded
          ),
        AppSnackbarTone.info => (
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
            Icons.info_rounded
          ),
      };

  /// The snackbar itself.
  @visibleForTesting
  static SnackBar build(
      BuildContext context, String message, AppSnackbarTone tone) {
    final ThemeData theme = Theme.of(context);
    final (Color bg, Color fg, IconData icon) =
        styleFor(theme.colorScheme, tone);
    return SnackBar(
      key: Key('app_snackbar_${tone.name}'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 3,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.sm,
          top: AppSpacing.md,
          bottom: AppSpacing.md),
      // Errors stay until read or closed; the rest leave on their own.
      duration: tone == AppSnackbarTone.error
          ? const Duration(seconds: 6)
          : const Duration(seconds: 4),
      showCloseIcon: tone == AppSnackbarTone.error,
      closeIconColor: fg,
      content: Row(
        children: <Widget>[
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
