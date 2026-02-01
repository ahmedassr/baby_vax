import 'package:baby_vax/app/core/imports/import_manger.dart';

class TipDetailsController extends GetxController with StateMixin , StateMixinHelper{
  final args = InternalScreenArgs.fromArgs.tip;
  TipsModel? tip;

  @override
  void onInit() {
    super.onInit();
    initializeTipArgument();
  }

  void initializeTipArgument() {
    if (args != null) {
      tip = args;
    }else{
      setError("TipDetailsController_missing_tip_msg".tr);
    }
  }

}
