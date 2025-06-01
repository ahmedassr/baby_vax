import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future fetchUserData() async {
    var uid = AppConstant.uid;
    if (uid.isEmpty) {
      setError("The user ID is missing.");
      return;
    }
    setLoading();
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection("user").doc(uid).get();
      if (doc.exists) {
        user.value = UserModel.fromDocument(doc);
        setSuccess();
      }
    } on FirebaseException catch (e) {
      setError(getFriendlyErrorMessage(e.toString()));
    }
  }
}
