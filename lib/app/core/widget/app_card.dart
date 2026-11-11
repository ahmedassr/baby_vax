import 'package:baby_vax/app/core/imports/import_manger.dart';

/// How far a card stands off the surface behind it. See [AppElevation].
enum AppCardLevel { flat, resting, raised }

/// The app's card: a theme surface with the radius, padding and elevation
/// from the design system, and an ink ripple when tappable.
///
/// Replaces eight hand-rolled `Container(decoration: BoxDecoration(...))`
/// cards from v1.0, each with its own colour pair, radius and shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.card,
    this.level = AppCardLevel.resting,
    this.color,
    this.borderRadius = AppRadius.lgAll,
    this.semanticLabel,
  });

  final Widget child;

  /// Makes the whole card one 48dp+ tap target.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;
  final AppCardLevel level;

  /// Fill. Defaults to the scheme's `surface`.
  final Color? color;

  final BorderRadius borderRadius;

  /// Read by TalkBack for the whole card instead of its children, for cards
  /// that are one tappable thing.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppElevation elevation = AppElevation.of(context);
    final AppElevationLevel l = switch (level) {
      AppCardLevel.flat => elevation.level0,
      AppCardLevel.resting => elevation.level1,
      AppCardLevel.raised => elevation.level2,
    };

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: content,
        ),
      );
    }

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: l.shadows,
      ),
      child: Material(
        color: color ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: l.borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );

    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        child: ExcludeSemantics(child: card),
      );
    }
    return card;
  }
}
