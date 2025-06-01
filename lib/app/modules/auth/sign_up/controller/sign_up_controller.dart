import 'package:intl/intl.dart';
import '../../../../core/imports/import_manger.dart';

class SignupController extends GetxController
    with StateMixin, StateMixinHelper {
  final signupControllers = {
    "emailController": TextEditingController(),
    "nameController": TextEditingController(),
    "passwordController": TextEditingController(),
    "birthdayController": TextEditingController(),
    "bloodPercentageController": TextEditingController(),
    "weightController": TextEditingController(),
    "headSizeController": TextEditingController(),
    "heightController": TextEditingController(),
  };
  final signupErrorText = {
    "emailErrorText": "".obs,
    "nameErrorText": "".obs,
    "passwordErrorText": "".obs,
    "birthdayErrorText": "".obs,
    "bloodPercentageErrorText": "".obs,
    "weightErrorText": "".obs,
    "headSizeErrorText": "".obs,
    "heightErrorText": "".obs,
  };
  Rx<DateTime> selectedBirthday = Rx<DateTime>(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    setSuccess();
    signupControllers["birthdayController"]?.text =
        DateFormat("yyyy-MM-dd").format(selectedBirthday.value);
  }

  Future<void> selectBirthday() async {
    final pickedDate = await Get.dialog(DatePickerDialog(
        initialDate: selectedBirthday.value,
        firstDate: DateTime(2000),
        lastDate: DateTime.now()));
    if (pickedDate != null) {
      selectedBirthday(pickedDate);
      signupControllers["birthdayController"]?.text =
          DateFormat("yyyy-MM-dd").format(pickedDate);
    } else {
      signupErrorText["birthdayErrorText"]?.value =
          "Date of birth can't be empty.";
    }
  }

  bool isValidate() {
    bool valid = true;
    if (signupControllers["emailController"]?.text.isEmpty ?? true) {
      signupErrorText["emailErrorText"]?.value = "Email can't be empty.";
      valid = false;
    }
    if (signupControllers["nameController"]?.text.isEmpty ?? true) {
      signupErrorText["nameErrorText"]?.value = "Name can't be empty.";
      valid = false;
    }
    if (signupControllers["passwordController"]?.text.isEmpty ?? true) {
      signupErrorText["passwordErrorText"]?.value = "Password can't be empty.";
      valid = false;
    }
    if (signupControllers["birthdayController"]?.text.isEmpty ?? true) {
      signupErrorText["birthdayErrorText"]?.value =
          "Date of birth can't be empty.";
      valid = false;
    }
    if (signupControllers["bloodPercentageController"]?.text.isEmpty ?? true) {
      signupErrorText["bloodPercentageErrorText"]?.value =
          "Blood percentage can't be empty.";
      valid = false;
    }
    if (signupControllers["weightController"]?.text.isEmpty ?? true) {
      signupErrorText["weightErrorText"]?.value = "Weight can't be empty.";
      valid = false;
    }
    if (signupControllers["headSizeController"]?.text.isEmpty ?? true) {
      signupErrorText["headSizeErrorText"]?.value = "Head size can't be empty.";
      valid = false;
    }
    if (signupControllers["heightController"]?.text.isEmpty ?? true) {
      signupErrorText["heightErrorText"]?.value = "Height can't be empty.";
      valid = false;
    }
    return valid;
  }

  Future<void> userSignup() async {
    if (!isValidate()) {
      return;
    }
    UserModel user = UserModel(
        uid: "",
        email: signupControllers["emailController"]?.text.trim() ?? "",
        birthday: signupControllers["birthdayController"]?.text.trim() ?? "",
        name: signupControllers["nameController"]?.text.trim() ?? "",
        height: signupControllers["heightController"]?.text.trim() ?? "",
        weight: signupControllers["weightController"]?.text.trim() ?? "",
        headSize: signupControllers["headSizeController"]?.text.trim() ?? "",
        bloodPercentage:
            signupControllers["bloodPercentageController"]?.text.trim() ?? "");

    setLoading();
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: signupControllers["emailController"]?.text.trim() ?? "",
          password: signupControllers["passwordController"]?.text.trim() ?? "");
      if (result.user != null) {
        user.uid = result.user?.uid ?? "";
        createUser(user);
      }
    } on FirebaseException catch (e) {
      setError(getFriendlyErrorMessage(e.toString()));
    }
  }

  Future createUser(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set(user.toMap());
      final snapShot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (snapShot.exists) {
        setSuccess();
        AppConstant.alertService.showAlert(AlertModel.success(
            message: "User created successfully.",
            yesAction: () => Get.toNamed(AppRoutes.mainMenu)));
      } else {
        setError("Failed to create user.");
      }
    } on FirebaseException catch (e) {
      setError(getFriendlyErrorMessage(e.toString()));
    }
  }
}
