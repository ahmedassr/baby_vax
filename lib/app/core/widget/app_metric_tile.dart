import 'package:baby_vax/app/core/imports/import_manger.dart';

/// One measurement: icon, label, value with its unit, and optionally when it
/// was taken.
///
/// Replaces v1.0's `MeasurementCard`, which fixed its aspect ratio at 0.95 in
/// a grid (so a 1.3 text scale pushed the value out of the card) and had a
/// no-op `onTap`.
class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.caption,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// The number, or a dash when unknown.
  final String value;

  /// "kg", "cm". Omitted when [value] is a dash.
  final String? unit;

  /// Small line under the value: "on 3 Mar 2027", "around the 50th
  /// percentile".
  final String? caption;

  final VoidCallback? onTap;

  /// What to show for a measurement the parent has not entered.
  static const String empty = '—';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasValue = value.trim().isNotEmpty && value != empty;
    final String shown = hasValue ? value : empty;
    final String spoken = hasValue && unit != null
        ? '$label, $value $unit'
        : '$label, ${hasValue ? value : "not_recorded_label".tr}';

    return AppCard(
      onTap: onTap,
      semanticLabel: caption == null ? spoken : '$spoken, $caption',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIconBadge(icon: icon, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(children: <InlineSpan>[
              TextSpan(text: shown, style: theme.textTheme.titleLarge),
              if (hasValue && unit != null)
                TextSpan(text: ' $unit', style: theme.textTheme.bodySmall),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null)
            Text(caption!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
