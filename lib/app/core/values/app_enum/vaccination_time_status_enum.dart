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
        return "Overdue";
      case VaccinationTimeStatusEnum.today:
        return "Today";
      case VaccinationTimeStatusEnum.hoursLeft:
        return "Hours Left";
      case VaccinationTimeStatusEnum.tomorrow:
        return "Tomorrow";
      case VaccinationTimeStatusEnum.daysLeft:
        return "Days Left";
      case VaccinationTimeStatusEnum.weeksLeft:
        return "Weeks Left";
      case VaccinationTimeStatusEnum.monthsLeft:
        return "Months Left";
      case VaccinationTimeStatusEnum.yearsLeft:
        return "Years Left";
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
