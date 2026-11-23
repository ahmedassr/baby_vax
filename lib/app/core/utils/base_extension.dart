import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Gap helpers: `16.sbh` is a 16dp vertical gap, `8.sbw` an 8dp horizontal
/// one.
///
/// Logical pixels since v1.1. These used to go through ScreenUtil (`.h`,
/// `.w`), which scaled them by the screen's height or width against a
/// 414x896 design, so on a 360x640 phone a "20" gap became 14dp while the
/// text next to it stayed the same size. Use values from [AppSpacing].
extension SizedBoxExtension on num {
  SizedBox get sbh => SizedBox(height: toDouble());

  SizedBox get sbw => SizedBox(width: toDouble());
}
