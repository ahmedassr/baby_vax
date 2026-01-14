import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/main/controller/main_controller.dart';

class EditUserController extends GetxController
    with StateMixin, StateMixinHelper {
  final editUserController = {
    "email": TextEditingController(),
    "name": TextEditingController(),
    "weight": TextEditingController(),
    "height": TextEditingController(),
    "bloodPercentage": TextEditingController(),
    "headSize": TextEditingController(),
  };
  final userArg = InternalScreenArgs.fromArgs.user;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initializeUserArgument();
  }

  void initializeUserArgument() {
    if (userArg == null) return;
    editUserController["email"]?.text = userArg?.email ?? "";
    editUserController["name"]?.text = userArg?.name ?? "-";
    editUserController["weight"]?.text = userArg?.weight ?? "";
    editUserController["height"]?.text = userArg?.height ?? "";
    editUserController["bloodPercentage"]?.text =
        userArg?.bloodPercentage ?? "";
    editUserController["headSize"]?.text = userArg?.headSize ?? "";
  }

  Future<void> updateUser() async {
    setLoading();
    try {
      final updatedUser = UserModel(
        uid: SessionManager.uId,
        email: editUserController["email"]?.text.trim() ?? "",
        birthday: userArg?.birthday ?? "",
        name: editUserController["name"]?.text.trim() ?? "",
        height: editUserController["height"]?.text.trim() ?? "",
        weight: editUserController["weight"]?.text.trim() ?? "",
        bloodPercentage:
            editUserController["bloodPercentage"]?.text.trim() ?? "",
        headSize: editUserController["headSize"]?.text.trim() ?? "",
      );
      await AppConstant.fireStoreHelper.updateData(
          path: ["users", SessionManager.uId], date: updatedUser.toMap());

      Get.find<MainController>().fetchUserData();
      setSuccess();
      Get.back();
    } catch (_) {
      setError("Failed to update user.");
    }
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    editUserController.forEach((key, value) => value.dispose());
  }
}
