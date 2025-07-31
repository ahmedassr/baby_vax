import 'package:baby_vax/app/core/imports/import_manger.dart';

class MainController extends GetxController with StateMixin, StateMixinHelper {
  final Rxn<UserModel> userDetails = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future fetchUserData() async {
    var uid = AppConstant.uId;
    if (uid.isEmpty) {
      setError("The user ID is missing.");
      return;
    }
    setLoading();
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (doc.exists) {
        userDetails.value = UserModel.fromDocument(doc);
        setSuccess();
      }else{
        setError("User date not found.");
      }
    } on FirebaseException catch (e) {
      setError(getFriendlyErrorMessage(e.toString()));
    }
  }
}
