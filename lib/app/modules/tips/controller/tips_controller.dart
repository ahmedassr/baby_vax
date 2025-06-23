import 'package:baby_vax/app/core/imports/import_core.dart';
import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/modules/tips/model/tips_model.dart';

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
    await Future.delayed(const Duration(seconds: 2));
    tips.assignAll([
      TipsModel(title: "title 1 ", description: "description 1"),
      TipsModel(title: "title 2 ", description: "description 2"),
      TipsModel(title: "title 3 ", description: "description 3")
    ]);
    setSuccess(tips);
  }
}
