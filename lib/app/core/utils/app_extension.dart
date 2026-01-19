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
  RemainingTimeResult get remainingTime {
    final difference = this.difference(DateTime.now());

    if (difference.inSeconds <= 0) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.overdue);
    }

    if (difference.inDays == 0 && difference.inHours >= 1) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.hoursLeft,
          value: difference.inHours);
    }

    if (difference.inDays == 0) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.today);
    }

    if (difference.inDays == 1) {
      return RemainingTimeResult(status: VaccinationTimeStatusEnum.tomorrow);
    }

    if (difference.inDays < 7) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.daysLeft, value: difference.inDays);
    }
    final weeks = (difference.inDays / 7).floor();
    if (weeks <= 4) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.weeksLeft, value: weeks);
    }
    final months = (difference.inDays / 30).floor();
    if (months <= 12) {
      return RemainingTimeResult(
          status: VaccinationTimeStatusEnum.monthsLeft, value: months);
    }

    final years = (months / 12).floor();
    return RemainingTimeResult(
        status: VaccinationTimeStatusEnum.yearsLeft, value: years);
  }
}
