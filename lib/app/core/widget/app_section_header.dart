import 'package:baby_vax/app/core/imports/import_manger.dart';

/// A section title, optionally with a subtitle and a trailing action.
///
/// Marked as a header for TalkBack, so a screen-reader user can jump between
/// sections with the headings gesture.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding =
        const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
  });

  final String title;
  final String? subtitle;

  /// Trailing text action ("See all"); shown only with [onAction].
  final String? actionLabel;
  final VoidCallback? onAction;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(title, style: text.titleMedium),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
