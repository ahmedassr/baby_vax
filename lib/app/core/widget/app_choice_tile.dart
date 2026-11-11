import 'package:baby_vax/app/core/imports/import_manger.dart';

/// One option in a small exclusive choice (girl / boy, repeat daily /
/// weekly), at least 56dp tall, announced by TalkBack as a selected or
/// unselected button in a group.
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(label,
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface)),
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.check_rounded,
                        size: 18, color: scheme.onPrimaryContainer),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
