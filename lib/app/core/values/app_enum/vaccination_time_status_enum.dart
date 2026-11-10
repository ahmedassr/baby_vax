import '../../imports/import_library.dart';

enum VaccinationTimeStatusEnum {
  overdue,
  today,
  tomorrow,
  hoursLeft,
  daysLeft,
  weeksLeft,
  monthsLeft,
  yearsLeft,
}

extension VaccinationTimeStatusExtension on VaccinationTimeStatusEnum {
  /// Translated label. Not called `name`: every Dart enum already has a
  /// built-in `name` getter, which wins over an extension member, so the
  /// badge used to show the raw identifier ("daysLeft").
  String get label {
    switch (this) {
      case VaccinationTimeStatusEnum.overdue:
        return "VaccinationTimeStatusEnum_overdue".tr;
      case VaccinationTimeStatusEnum.today:
        return "VaccinationTimeStatusEnum_today".tr;
      case VaccinationTimeStatusEnum.hoursLeft:
        return "VaccinationTimeStatusEnum_hoursLeft".tr;
      case VaccinationTimeStatusEnum.tomorrow:
        return "VaccinationTimeStatusEnum_tomorrow".tr;
      case VaccinationTimeStatusEnum.daysLeft:
        return "VaccinationTimeStatusEnum_daysLeft".tr;
      case VaccinationTimeStatusEnum.weeksLeft:
        return "VaccinationTimeStatusEnum_weeksLeft".tr;
      case VaccinationTimeStatusEnum.monthsLeft:
        return "VaccinationTimeStatusEnum_monthsLeft".tr;
      case VaccinationTimeStatusEnum.yearsLeft:
        return "VaccinationTimeStatusEnum_yearsLeft".tr;
    }
  }

  /// The countdown text: "3 days left", "1 week left", "Today".
  ///
  /// Arabic uses the "الأيام المتبقية: 3" form, which is correct for any
  /// number without Arabic's dual and plural agreement rules.
  String withCount(int? count) {
    if (count == null) return label;
    final String unit = switch (this) {
      VaccinationTimeStatusEnum.daysLeft => 'days',
      VaccinationTimeStatusEnum.weeksLeft => 'weeks',
      VaccinationTimeStatusEnum.monthsLeft => 'months',
      VaccinationTimeStatusEnum.yearsLeft => 'years',
      VaccinationTimeStatusEnum.hoursLeft => 'hours',
      _ => '',
    };
    if (unit.isEmpty) return label;
    final String form = count == 1 ? 'one' : 'other';
    return 'VaccinationTimeStatus_${unit}_left_$form'
        .trParams({'count': '$count'});
  }

  Color badgeBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    double alpha(double light, double dark) => isDark ? dark : light;

    switch (this) {
      case VaccinationTimeStatusEnum.overdue:
        return scheme.error.withValues(alpha: alpha(0.12, 0.28));

      case VaccinationTimeStatusEnum.today:
      case VaccinationTimeStatusEnum.hoursLeft:
        return scheme.tertiary.withValues(alpha: alpha(0.14, 0.3));

      case VaccinationTimeStatusEnum.tomorrow:
        return scheme.secondary.withValues(alpha: alpha(0.14, 0.3));

      case VaccinationTimeStatusEnum.daysLeft:
        return scheme.primary.withValues(alpha: alpha(0.14, 0.3));

      case VaccinationTimeStatusEnum.weeksLeft:
        return scheme.primary.withValues(alpha: alpha(0.12, 0.26));

      case VaccinationTimeStatusEnum.monthsLeft:
        return scheme.primary.withValues(alpha: alpha(0.1, 0.22));

      case VaccinationTimeStatusEnum.yearsLeft:
        return scheme.primary.withValues(alpha: alpha(0.08, 0.18));
    }
  }
}
