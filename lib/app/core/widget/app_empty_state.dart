import 'package:baby_vax/app/core/imports/import_manger.dart';

/// "There is nothing here yet", with what to do about it.
///
/// v1.0's version had an English default (`"No data found."`), showed the
/// Tips string on screens that were not Tips, and offered no way forward.
/// Now a title is required, the body is optional, and an optional action
/// gives the parent something to tap.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.animationPath,
    this.actionLabel,
    this.onAction,
    this.scrollable = true,
  });

  /// False when placed inside another scroll view (a sliver list), so it
  /// lays out as a plain column instead of filling and scrolling.
  final bool scrollable;

  final String title;
  final String? message;

  /// Shown when no [animationPath] is given.
  final IconData icon;

  /// A Lottie file to play instead of the icon.
  final String? animationPath;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      visual: animationPath != null
          ? ExcludeSemantics(
              child: Lottie.asset(animationPath!, height: 160, repeat: false),
            )
          : _StateIcon(icon: icon),
      title: title,
      message: message,
      scrollable: scrollable,
      action: actionLabel != null && onAction != null
          ? AppButton(
              text: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
              expand: false,
            )
          : null,
    );
  }
}

/// "Something went wrong", inline, with Retry.
///
/// Replaces v1.0's pattern of returning `SizedBox.shrink()` from `onError`
/// and opening a dialog from a post-frame callback, which emptied the screen
/// behind the dialog.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  /// Defaults to a generic "Something went wrong".
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return _StateLayout(
      visual: _StateIcon(
        icon: Icons.cloud_off_rounded,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      title: title ?? "state_error_title".tr,
      message: message,
      liveRegion: true,
      action: onRetry == null
          ? null
          : AppButton(
              text: "retry_label".tr,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              variant: AppButtonVariant.outline,
              expand: false,
            ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, this.background, this.foreground});

  final IconData icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppIconBadge(
      icon: icon,
      size: 72,
      background: background ?? scheme.surfaceContainerHigh,
      foreground: foreground ?? scheme.onSurfaceVariant,
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.visual,
    required this.title,
    this.message,
    this.action,
    this.liveRegion = false,
    this.scrollable = true,
  });

  final bool scrollable;
  final Widget visual;
  final String title;
  final String? message;
  final Widget? action;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget body = Semantics(
      liveRegion: liveRegion,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          visual,
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(message!,
                style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    );
    if (!scrollable) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
        child: Center(child: body),
      );
    }
    // Scrollable so a 1.3 text scale on a 360x640 screen never overflows,
    // and so pull-to-refresh can wrap it.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? constraints.maxHeight - 2 * AppSpacing.xxxl
                : 0,
          ),
          child: Center(child: body),
        ),
      ),
    );
  }
}
