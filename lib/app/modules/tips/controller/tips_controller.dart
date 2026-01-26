import 'package:baby_vax/app/core/imports/import_manger.dart';

class TipsController extends GetxController
    with StateMixin<List<TipsModel>>, StateMixinHelper {
  List<TipsModel> tips = <TipsModel>[].obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchTips();
  }

  Future<void> fetchTips() async {
    setLoading();
    try {
      final tips = await AppConstant.fireStoreHelper
          .fetchData(path: ["tips"], fromDocument: TipsModel.fromDocument);
      if (tips?.isEmpty ?? true) {
        setEmpty();
      } else {
        setSuccess(tips);
      }
    } catch (_) {
      setError("TipsController_fetch_failed_msg".tr);
    }
  }

  void onTipPressed(TipsModel tip) {
    Get.toNamed(AppRoutes.tipDetails);
    AppConstant.argumentService.setArgument(InternalScreenArgs(tip: tip));
  }
}
