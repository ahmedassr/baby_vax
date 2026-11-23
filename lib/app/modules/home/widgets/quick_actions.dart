import 'package:baby_vax/app/core/imports/import_manger.dart';

/// One shortcut on the home screen.
class QuickAction {
  const QuickAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Shortcuts to the things a parent does between appointments: share the
/// vaccination card, add a measurement, add a reminder. Equal-width tiles
/// whose labels may wrap to two lines at large text sizes.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCard(
                key: actions[i].key,
                onTap: actions[i].onTap,
                semanticLabel: actions[i].label,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppIconBadge(icon: actions[i].icon),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      actions[i].label,
                      style: theme.textTheme.labelLarge,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
