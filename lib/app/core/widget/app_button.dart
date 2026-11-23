import 'package:baby_vax/app/core/imports/import_manger.dart';

/// The four kinds of button in the app.
enum AppButtonVariant {
  /// Filled brand green, white label. One per screen: the thing to do next.
  primary,

  /// Tonal green container. Secondary actions next to a primary one.
  secondary,

  /// Outlined. A neutral alternative ("Back", "Skip for now").
  outline,

  /// Error-coloured outline. Destructive or "not doing it" actions
  /// (skip a dose, delete a reminder).
  danger,
}

/// The app's button.
///
/// v1.0 had one `AppButton` that painted primary-coloured text on a pale
/// green fill at 2.9:1, wrapped itself in 20dp of horizontal padding the
/// caller could not remove, and sized its label with
/// `headLineSmall.copyWith(fontSize: 22)`. Destructive actions were bare
/// `TextButton`s with no 48dp box.
///
/// Now every variant is at least 48dp tall, its colours come from the theme,
/// and [loading] swaps the label for a spinner while keeping the button's
/// size, so the layout does not jump while a save is in flight.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  /// The label. Always visible text, never icon-only, so TalkBack reads it.
  final String text;

  /// Null disables the button.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  /// Shows a spinner instead of the label and ignores taps.
  final bool loading;

  /// Fill the available width (the default for bottom actions).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // While loading the button keeps its enabled colours (a grey disabled
    // fill would flash) and simply ignores taps.
    final VoidCallback? action = loading ? _ignore : onPressed;

    final Widget label = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _foreground(scheme),
            ),
          )
        : Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );

    final Widget child = icon == null || loading
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: label),
            ],
          );

    final Size minimum = Size(
      expand ? double.infinity : AppSpacing.minTouchTarget,
      AppSpacing.minTouchTarget,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(minimumSize: minimum),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(minimumSize: minimum),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(minimumSize: minimum),
          child: child,
        ),
      AppButtonVariant.danger => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            minimumSize: minimum,
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          child: child,
        ),
    };

    // While loading the button is disabled, which TalkBack would announce as
    // "dimmed" with no reason. Say what is happening instead.
    return Semantics(
      liveRegion: loading,
      label: loading ? "loading_label".tr : null,
      child: IgnorePointer(ignoring: loading, child: button),
    );
  }

  static void _ignore() {}

  Color _foreground(ColorScheme scheme) => switch (variant) {
        AppButtonVariant.primary => scheme.onPrimary,
        AppButtonVariant.secondary => scheme.onPrimaryContainer,
        AppButtonVariant.outline => scheme.primary,
        AppButtonVariant.danger => scheme.error,
      };
}
