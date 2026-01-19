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
  String get name{
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
    switch (this) {
      case VaccinationTimeStatusEnum.overdue:
        return Colors.red.shade600;
      case VaccinationTimeStatusEnum.today:
        return Colors.orange.shade600;
      case VaccinationTimeStatusEnum.hoursLeft:
        return Colors.orange.shade500;
      case VaccinationTimeStatusEnum.tomorrow:
        return Colors.amber.shade500;
      case VaccinationTimeStatusEnum.daysLeft:
        return theme.colorScheme.primary.withValues(alpha: 0.9);
      case VaccinationTimeStatusEnum.weeksLeft:
        return theme.colorScheme.primary.withValues(alpha: 0.75);
      case VaccinationTimeStatusEnum.monthsLeft:
        return theme.colorScheme.primary.withValues(alpha: 0.6);
      case VaccinationTimeStatusEnum.yearsLeft:
        return theme.colorScheme.primary.withValues(alpha: 0.45);
    }
  }
}
