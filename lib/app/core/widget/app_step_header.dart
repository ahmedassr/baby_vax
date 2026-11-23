import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Progress through a multi-step flow: "Step 2 of 5 · Your baby", with a
/// segmented bar under it.
///
/// Used by the sign-up stepper and onboarding. The bar is one segment per
/// step rather than a single fill, so a parent can see how many steps
/// remain without reading the number.
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({
    super.key,
    required this.current,
    required this.total,
    required this.title,
  });

  /// Zero-based index of the step being shown.
  final int current;
  final int total;

  /// The current step's name.
  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String counter = "step_counter"
        .trParams({'current': '${current + 1}', 'total': '$total'});

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$counter, $title',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(counter,
              style:
                  theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              for (int i = 0; i < total; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= current
                          ? scheme.primary
                          : scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
