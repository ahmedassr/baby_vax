import 'package:baby_vax/app/core/imports/import_manger.dart';

/// How far a card stands off the surface behind it. See [AppElevation].
enum AppCardLevel { flat, resting, raised }

/// The app's card: a theme surface with the radius, padding and elevation
/// from the design system, and an ink ripple when tappable.
///
/// Replaces eight hand-rolled `Container(decoration: BoxDecoration(...))`
/// cards from v1.0, each with its own colour pair, radius and shadow.
class AppCard extends StatefulWidget {
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
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppElevation elevation = AppElevation.of(context);
    // Keyboard focus (which Android can switch on with the Back key) is
    // shown as a ring, never as a fill: a card's background is the same in
    // every state, so one card in a list can never look different from
    // the rest (phone review R5a).
    final bool ring = _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final AppElevationLevel l = switch (widget.level) {
      AppCardLevel.flat => elevation.level0,
      AppCardLevel.resting => elevation.level1,
      AppCardLevel.raised => elevation.level2,
    };

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.onTap != null) {
      content = InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onFocusChange: (bool f) => setState(() => _focused = f),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: content,
        ),
      );
    }

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: l.shadows,
      ),
      child: Material(
        color: widget.color ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius,
          side:
              ring ? BorderSide(color: scheme.primary, width: 2) : l.borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );

    if (widget.semanticLabel != null) {
      card = Semantics(
        container: true,
        button: widget.onTap != null,
        label: widget.semanticLabel,
        child: ExcludeSemantics(child: card),
      );
    }
    return card;
  }
}
