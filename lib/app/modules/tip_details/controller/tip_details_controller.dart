import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Holds the tip opened from the list.
class TipDetailsController extends GetxController {
  TipDetailsController({TipsModel? tip})
      : tip = tip ?? InternalScreenArgs.fromArgs.tip;

  /// Null when the screen was opened without a tip.
  final TipsModel? tip;
}
