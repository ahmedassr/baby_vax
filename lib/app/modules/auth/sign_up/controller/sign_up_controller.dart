import 'dart:math';

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
}
