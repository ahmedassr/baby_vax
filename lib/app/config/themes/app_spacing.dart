import '../../core/imports/import_library.dart';

/// The app's spacing scale, on a 4dp grid.
///
/// v1.0 had three `EdgeInsets` here and wrote every other gap inline: 5, 6,
/// 8, 10, 12, 14, 15, 16, 18, 20, 22, 24, 28, 30, 32, 40, 64 and 70 all
/// appear in `lib/app/modules/`. Anything not on this scale is a bug.
///
/// Values are logical pixels, not `ScreenUtil` units. The two are easy to
/// confuse and mixing them is why v1.0 scaled a handful of widgets (those
/// using `.w`/`.h`/`.r`) and left the rest fixed, so gaps and touch targets
/// moved independently of each other on a small screen.
class AppSpacing {
  const AppSpacing._();

  /// 2dp — hairline separation inside a chip.
  static const double xxs = 2;

  /// 4dp — between a label and the value under it.
  static const double xs = 4;

  /// 8dp — between related items in a row.
  static const double sm = 8;

  /// 12dp — between cards in a list.
  static const double md = 12;

  /// 16dp — the screen gutter, and card padding.
  static const double lg = 16;

  /// 20dp.
  static const double xl = 20;

  /// 24dp — between sections.
  static const double xxl = 24;

  /// 32dp.
  static const double xxxl = 32;

  /// 40dp — above a lone primary action.
  static const double huge = 40;

  /// The minimum touch target, per the Material and Android accessibility
  /// guidelines. Any tappable thing smaller than this is a defect.
  static const double minTouchTarget = 48;

  // ---- ready-made insets ------------------------------------------------

  /// The standard screen gutter.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);

  /// A scrolling screen's content padding.
  static const EdgeInsets screenVertical =
      EdgeInsets.symmetric(horizontal: lg, vertical: lg);

  /// Inside an [AppCard].
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Inside a bottom sheet, with room for the drag handle.
  static const EdgeInsets sheet =
      EdgeInsets.only(left: xl, right: xl, top: md, bottom: xxl);

  // ---- names kept from v1.0 ---------------------------------------------
  // Still referenced by screens that have not been moved onto the system
  // yet. They now resolve to scale values instead of 15/10/5/30.

  /// Padding around a screen's bottom action button.
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: lg);

  /// A column's own padding inside a screen.
  static const EdgeInsets columnPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  /// A list item's padding.
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: sm, vertical: sm);
}

/// The app's corner radii.
class AppRadius {
  const AppRadius._();

  /// 8dp — small controls.
  static const double sm = 8;

  /// 12dp — text fields and buttons.
  static const double md = 12;

  /// 16dp — cards.
  static const double lg = 16;

  /// 24dp — sheets and the home hero card.
  static const double xl = 24;

  /// Fully rounded — status chips and badges.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// A sheet's top corners only.
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
}
