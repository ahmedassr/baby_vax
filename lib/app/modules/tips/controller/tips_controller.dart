import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

class TipsController extends GetxController
    with StateMixin<List<TipsModel>>, StateMixinHelper {
  TipsController({Future<List<TipsModel>> Function(String collection)? load})
      : _load = load ?? _firestoreTips;

  final Future<List<TipsModel>> Function(String collection) _load;

  static Future<List<TipsModel>> _firestoreTips(String collection) =>
      AppConstant.fireStoreHelper1
          .getCollection(path: collection, fromDoc: TipsModel.fromDocument);

  @override
  void onInit() {
    super.onInit();
    fetchTips();
  }

  Future<void> fetchTips() async {
    // The rules only serve tips to signed-in users. This controller is
    // created at app start, so wait until someone is signed in; the tips tab
    // fetches again when opened.
    if (!SessionManager.isSignedIn) return;
    if (state == null || state!.isEmpty) setLoading();
    try {
      final String currentLanguage = Get.locale?.languageCode ?? "en";
      var collection =
          currentLanguage == "en" ? AppPath.tipsEnColl : AppPath.tipsColl;
      final tips = await _load(collection);
      if (tips.isEmpty) {
        setEmpty();
      } else {
        setSuccess(tips);
      }
    } catch (_) {
      setError("TipsController_fetch_failed_msg".tr);
    }
  }

  void onTipPressed(TipsModel tip) {
    AppConstant.argumentService.setArgument(InternalScreenArgs(tip: tip));
    Get.toNamed(AppRoutes.tipDetails);
  }
}
