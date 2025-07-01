import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/tips/model/tips_model.dart';

class TipDetailsController extends GetxController with StateMixin , StateMixinHelper{
  final args = InternalScreenArgs.fromArgs.tip;
  TipsModel? tip;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initializeTipArgument();
  }

  void initializeTipArgument() {
    if (args != null) {
      tip = args;
    }else{
      setError("The current tip is missing");
    }
  }
}
