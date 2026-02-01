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
  String get name {
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
