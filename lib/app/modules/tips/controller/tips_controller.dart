import 'package:baby_vax/app/config/constant/app_path.dart';
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
      var collection =
          currentLanguage == "en" ? AppPath.tipsEnColl : AppPath.tipsColl;
      // final tips = await AppConstant.fireStoreHelper
      //     .fetchData(path: [collection], fromDocument: TipsModel.fromDocument);
      final tips = await AppConstant.fireStoreHelper1
          .getCollection(path: collection, fromDoc: TipsModel.fromDocument);
      if (tips.isEmpty) {
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
