import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The tone of an [AppBanner].
enum AppBannerTone { info, success, warning, error }

/// An inline message with an optional action: "Notifications are off",
/// "Saved on this phone", "Incorrect email or password".
///
/// Inline rather than a dialog, so the form or list it is about stays
/// visible. Announced by TalkBack when it appears.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = AppBannerTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.icon,
  });

  final String message;
  final String? title;
  final AppBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shows a close button when set.
  final VoidCallback? onDismiss;

  /// Overrides the tone's default icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme s = theme.colorScheme;
    final (Color bg, Color fg, IconData defaultIcon) = switch (tone) {
      AppBannerTone.info => (
          s.tertiaryContainer,
          s.onTertiaryContainer,
          Icons.info_outline_rounded
        ),
      AppBannerTone.success => (
          s.primaryContainer,
          s.onPrimaryContainer,
          Icons.check_circle_outline_rounded
        ),
      AppBannerTone.warning => (
          s.secondaryContainer,
          s.onSecondaryContainer,
          Icons.warning_amber_rounded
        ),
      AppBannerTone.error => (
          s.errorContainer,
          s.onErrorContainer,
          Icons.error_outline_rounded
        ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.sm,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Icon(icon ?? defaultIcon, color: fg, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (title != null)
                        Text(title!,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: fg)),
                      Text(message,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(color: fg)),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: "close_label".tr,
                    icon: Icon(Icons.close_rounded, color: fg, size: 20),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            if (actionLabel != null && onAction != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
