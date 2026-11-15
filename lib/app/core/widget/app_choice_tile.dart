import 'package:baby_vax/app/core/imports/import_manger.dart';

/// One option of an [AppChoiceGroup].
class AppChoiceOption<T> {
  const AppChoiceOption({
    required this.value,
    required this.label,
    required this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData icon;

  /// The tile's key (tests find options by it).
  final Key? key;
}

/// A small exclusive choice (theme, girl / boy, repeat, growth metric) that
/// never breaks a word.
///
/// The phone review found "System" wrapped as "Syste m": three tiles with
/// the icon beside the label left too little room at 360dp. Now every
/// label is measured on one line at the current font and text scale:
///
/// - if each fits its share of the width, the options sit side by side,
///   icon above a single-line label;
/// - if not, it tries fewer per row (only counts that divide the options
///   evenly, so there is never a lone tile on the last row);
/// - and at one per row the options stack full width, icon beside the
///   label, which then wraps only between words.
class AppChoiceGroup<T> extends StatelessWidget {
  const AppChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    int? columns,
  }) : columns = columns ?? options.length;

  final List<AppChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  /// How many to put side by side when there is room. Defaults to all.
  final int columns;

  static const double gap = AppSpacing.sm;

  /// Horizontal padding inside a side-by-side tile.
  static const double _tilePadding = AppSpacing.sm;

  /// The widest label, on one line, as it would be drawn in [context].
  static double widestLabel(BuildContext context, Iterable<String> labels) {
    final ThemeData theme = Theme.of(context);
    double widest = 0;
    for (final String l in labels) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: l, style: AppChoiceTile.labelStyle(theme)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (p.width > widest) widest = p.width;
      p.dispose();
    }
    return widest;
  }

  /// How many options fit side by side in [width], given the widest label.
  @visibleForTesting
  static int columnsFor({
    required double width,
    required double widestLabel,
    required int count,
    required int preferred,
  }) {
    for (int c = preferred.clamp(1, count); c > 1; c--) {
      if (count % c != 0) continue;
      final double tile = (width - gap * (c - 1)) / c;
      // A pixel of slack so rounding never pushes a label onto two lines.
      if (widestLabel + 2 * _tilePadding + 1 <= tile) return c;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final int c = columnsFor(
        width: constraints.maxWidth,
        widestLabel: widestLabel(context, options.map((o) => o.label)),
        count: options.length,
        preferred: columns,
      );
      final bool stacked = c == 1;
      Widget tile(AppChoiceOption<T> o) => AppChoiceTile(
            key: o.key,
            label: o.label,
            icon: o.icon,
            selected: o.value == selected,
            onTap: () => onSelected(o.value),
            axis: stacked ? Axis.horizontal : Axis.vertical,
          );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int row = 0; row * c < options.length; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: gap),
            if (stacked)
              tile(options[row])
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = row * c; i < (row + 1) * c; i++) ...<Widget>[
                      if (i > row * c) const SizedBox(width: gap),
                      Expanded(child: tile(options[i])),
                    ],
                  ],
                ),
              ),
          ],
        ],
      );
    });
  }
}

/// One option in a small exclusive choice, at least 56dp tall, announced by
/// TalkBack as a selected or unselected button in a group. Lay options out
/// with [AppChoiceGroup], which picks [axis].
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.axis = Axis.horizontal,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// [Axis.vertical]: icon above a single-line label (side by side tiles).
  /// [Axis.horizontal]: icon beside the label (a full-width tile).
  final Axis axis;

  static TextStyle? labelStyle(ThemeData theme) => theme.textTheme.titleSmall;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final Widget iconWidget = Icon(icon,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant);
    final Widget check =
        Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary);
    final TextStyle? style = labelStyle(theme)?.copyWith(color: fg);

    final Widget content = axis == Axis.vertical
        ? Stack(
            children: <Widget>[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppChoiceGroup._tilePadding,
                      vertical: AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      iconWidget,
                      const SizedBox(height: AppSpacing.xs),
                      Text(label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: style),
                    ],
                  ),
                ),
              ),
              // A corner badge, so the label keeps the tile's full width.
              if (selected)
                PositionedDirectional(
                    top: AppSpacing.xs, end: AppSpacing.xs, child: check),
            ],
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                iconWidget,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(label, style: style)),
                if (selected) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  check,
                ],
              ],
            ),
          );

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: content,
          ),
        ),
      ),
    );
  }
}
