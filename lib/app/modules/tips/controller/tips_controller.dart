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
      final currentLanguage =
          AppConstant.getStorage.read(StorageKey.languageKey) ?? "en";
      var collection = currentLanguage == "en" ? "tips_en" : "tips";
      final tips = await AppConstant.fireStoreHelper
          .fetchData(path: [collection], fromDocument: TipsModel.fromDocument);
      if (tips?.isEmpty ?? true) {
        setEmpty();
        logger.w("empty");
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
