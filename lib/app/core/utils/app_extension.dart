import '../imports/import_manger.dart';

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

