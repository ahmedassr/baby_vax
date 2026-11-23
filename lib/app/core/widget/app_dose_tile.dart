import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/core/utils/app_extension.dart';
import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';

/// The countdown text for a pending dose ("3 days left", "Tomorrow",
/// "متبقٍ شهران"), or null for a dose that is done, skipped or overdue.
///
/// Uses the CLDR plural rules through
/// [VaccinationTimeStatusExtension.withCount], so Arabic gets the correct
/// dual and plural forms.
String? doseCountdown(MedicalDatesModel dose, DateTime now) {
  if (VaccineStatePolicy.displayStatus(dose, now) !=
      DoseDisplayStatus.pending) {
    return null;
  }
  final result = dose.date.remainingTimeFrom(now);
  return result.status.withCount(result.value);
}

/// One dose in a list: name, status, date and — when pending — a countdown.
///
/// The vaccine name is the headline because that is what a parent scans
/// for; v1.0 led with the date. Long names wrap to two lines and then
/// ellipsise, never clip (the 2-line Arabic fix from v1.0's fix 11).
///
/// The chip sits *under* the name rather than beside it, so at text scale
/// 1.3 on a 360dp screen a long Arabic name still has the full width.
class AppDoseTile extends StatelessWidget {
  const AppDoseTile({
    super.key,
    required this.dose,
    this.onTap,
    this.now,
  });

  final MedicalDatesModel dose;
  final VoidCallback? onTap;

  /// Defaults to the current time. Injectable for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime today = now ?? DateTime.now();
    final DoseDisplayStatus status =
        VaccineStatePolicy.displayStatus(dose, today);
    final String date = AppDateFormat.date(dose.date);
    final String? countdown = doseCountdown(dose, today);
    final String name = dose.displayName;

    final String semantic = <String>[
      name,
      status.translationKey.tr,
      date,
      if (countdown != null) countdown,
    ].join(', ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      semanticLabel: semantic,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bidiIsolate(name),
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    AppStatusChip(status: status, dense: true),
                    Text(
                      countdown == null ? date : '$date · $countdown',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
