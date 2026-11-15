import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Which tip Home shows today.
///
/// The same tip all day, the next one tomorrow, cycling through every tip
/// in a stable order (by document id, so a refresh that returns the tips
/// in another order does not change today's pick). Needs no network: it
/// picks from the tips already loaded, which Firestore serves from its
/// on-device cache when offline.
class TipOfTheDay {
  const TipOfTheDay._();

  /// The first day of the rotation. Any fixed date works.
  static final DateTime _epoch = DateTime.utc(2024);

  static TipsModel? pick(List<TipsModel> tips, DateTime now) {
    if (tips.isEmpty) return null;
    final List<TipsModel> ordered = List<TipsModel>.of(tips)
      ..sort((TipsModel a, TipsModel b) =>
          (a.id ?? a.title).compareTo(b.id ?? b.title));
    // Calendar days, not 24-hour periods, in the phone's own time zone.
    final int day =
        DateTime.utc(now.year, now.month, now.day).difference(_epoch).inDays;
    return ordered[day % ordered.length];
  }
}
