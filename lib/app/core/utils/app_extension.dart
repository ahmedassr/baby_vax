import '../imports/import_manger.dart';
import '../shared_model/remaining_time_result.dart';
import '../values/app_enum/vaccination_time_status_enum.dart';

extension ListFilterExtension<T> on List<T> {
  void filterBy(
    String query, {
    required bool Function(T item, String query) predicate,
    required void Function(List<T> result) onSuccess,
    required VoidCallback onEmpty,
  }) {
    if (query.isEmpty) {
      onSuccess(List.from(this));
      return;
    }
    final filtered = where((item) => predicate(item, query)).toList();
    if (filtered.isEmpty) {
      onEmpty();
    } else {
      onSuccess(filtered);
    }
  }
}

extension RemainingTimeExtension on DateTime {
  RemainingTimeResult get remainingTime => remainingTimeFrom(DateTime.now());

  /// Time until this date, counted in whole calendar days.
  ///
  /// A dose is due on a day, so a dose due today is "Today" for the whole day
  /// and only becomes overdue from tomorrow. The previous version compared
  /// instants, so a dose stored at midnight showed as overdue on its own day.
  ///
  /// Days are counted on UTC calendar dates so a DST change between now and
  /// the due date cannot turn 23 or 25 hours into the wrong number of days.
  RemainingTimeResult remainingTimeFrom(DateTime now) {
    final int days = DateTime.utc(year, month, day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;

    if (days < 0) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.overdue);
    }
    if (days == 0) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.today);
    }
    if (days == 1) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.tomorrow);
    }
    if (days < 7) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.daysLeft, value: days);
    }
    final int weeks = days ~/ 7;
    if (weeks <= 4) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.weeksLeft, value: weeks);
    }
    final int months = days ~/ 30;
    if (months <= 12) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.monthsLeft, value: months);
    }
    return RemainingTimeResult(
        status: VaccinationTimeStatusEnum.yearsLeft, value: months ~/ 12);
  }
}
