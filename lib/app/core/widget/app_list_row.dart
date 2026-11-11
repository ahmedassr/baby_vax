import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A settings-style row: leading icon, title, optional subtitle, and a
/// trailing value, widget or chevron. At least 48dp tall.
///
/// Replaces v1.0's `AppListTitleItem` (a bordered box with its own shadow,
/// laid out 20dp apart) and the unused `AppListItem`. Rows are meant to be
/// grouped inside one [AppCard] with dividers between them, the way Android
/// settings screens are.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Short trailing text: "English", "On", "1.1.0".
  final String? value;

  /// Replaces [value] and the chevron.
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Error-coloured: "Delete account".
  final bool destructive;

  /// Defaults to true when tappable and no [trailing] is given.
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color ink = destructive ? scheme.error : scheme.onSurface;
    final bool chevron = showChevron ?? (onTap != null && trailing == null);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  AppIconBadge(
                    icon: icon!,
                    size: 36,
                    background: destructive
                        ? scheme.errorContainer
                        : scheme.surfaceContainerHigh,
                    foreground: destructive
                        ? scheme.onErrorContainer
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(title,
                          style:
                              theme.textTheme.bodyLarge?.copyWith(color: ink)),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (value != null)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                    child: Text(value!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                if (chevron)
                  Icon(
                    rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Several [AppListRow]s in one card, separated by inset dividers.
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
            const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg));
      }
      rows.add(children[i]);
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: rows),
    );
  }
}
