import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> userDetails = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future fetchUserData() async {
    var uid = SessionManager.uId;
    if (uid.isEmpty) {
      setError("The user ID is missing.");
      return;
    }
    setLoading();
    try {
      final data = await AppConstant.fireStoreHelper
          .getUser(uid: uid, fromMap: (e) => UserModel.fromJson(e));
      if (data == null) {
        setEmpty();
      } else {
        userDetails.value = data;
        setSuccess();
      }
    } catch (_) {
      setError("An unexpected error occurred.");
    }
  }
}
