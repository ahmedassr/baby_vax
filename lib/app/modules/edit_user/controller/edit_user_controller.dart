import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

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
        uid: SessionManager.signedInUid ?? "",
        email: editUserController["email"]?.text.trim() ?? "",
        birthday: userArg?.birthday ?? "",
        name: editUserController["name"]?.text.trim() ?? "",
        height: editUserController["height"]?.text.trim() ?? "",
        weight: editUserController["weight"]?.text.trim() ?? "",
        bloodPercentage:
            editUserController["bloodPercentage"]?.text.trim() ?? "",
        headSize: editUserController["headSize"]?.text.trim() ?? "",
      );
      // Returns once the change is stored on the device. Offline it does not
      // wait for the server; Firestore sends it when the phone reconnects.
      final WriteOutcome outcome = await AppConstant.fireStoreHelper1
          .updateData(path: AppPath.currentUserDoc, data: updatedUser.toMap());

      Get.find<HomeController>().fetchUserData();
      setSuccess();
      AppConstant.alertService.showAlert(AlertModel.success(
        message: outcome == WriteOutcome.pendingSync
            ? "saved_offline_msg".tr
            : "SignupController_updated_user_success_msg".tr,
        yesAction: Get.back,
      ));
    } catch (_) {
      setError("EditUserController_update_user_failed".tr);
    }
  }

  @override
  void onClose() {
    super.onClose();
    editUserController.forEach((key, value) => value.dispose());
  }
}
