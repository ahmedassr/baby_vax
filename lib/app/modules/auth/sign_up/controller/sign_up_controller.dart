import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:intl/intl.dart';
import '../../../../config/constant/app_path.dart';
import '../../../../core/imports/import_manger.dart';
import '../../../home/controller/home_controller.dart';

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
  Rx<DateTime> selectedBirthday = Rx<DateTime>(
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute,
    ),
  );
  final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void onInit() {
    super.onInit();
    setSuccess();
    signupControllers["birthdayController"]?.text =
        dateFormat.format(selectedBirthday.value);
  }

  @override
  void onClose() {
    signupControllers.forEach((_, c) => c.dispose());
    super.onClose();
  }

  Future<void> selectBirthday() async {
    final context = Get.context;
    if (context == null || !context.mounted) return;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: selectedBirthday.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !context.mounted) return;

    final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedBirthday.value));

    if (!context.mounted) return;

    selectedBirthday.value = selectedTime == null
        ? selectedDate
        : DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );

    signupControllers["birthdayController"]?.text =
        dateFormat.format(selectedBirthday.value);
  }

  bool isValidate() {
    bool valid = true;
    for (var text in signupErrorText.values) {
      text.value = "";
    }
    if (signupControllers["emailController"]?.text.isEmpty ?? true) {
      signupErrorText["emailErrorText"]?.value = "empty_email_error_msg".tr;
      valid = false;
    }
    if (signupControllers["nameController"]?.text.isEmpty ?? true) {
      signupErrorText["nameErrorText"]?.value = "empty_name_error_msg".tr;
      valid = false;
    }
    if (signupControllers["passwordController"]?.text.isEmpty ?? true) {
      signupErrorText["passwordErrorText"]?.value =
          "empty_password_error_msg".tr;
      valid = false;
    }
    final String birthdayText =
        signupControllers["birthdayController"]?.text.trim() ?? "";
    if (birthdayText.isEmpty) {
      signupErrorText["birthdayErrorText"]?.value =
          "empty_date_of_birth_error_msg".tr;
      valid = false;
    } else {
      // Validate here rather than letting the generator throw mid-signup,
      // after the Auth user has already been created.
      final String? birthdayError = _birthDateError(birthdayText);
      if (birthdayError != null) {
        signupErrorText["birthdayErrorText"]?.value = birthdayError;
        valid = false;
      }
    }
    if (signupControllers["bloodPercentageController"]?.text.isEmpty ?? true) {
      signupErrorText["bloodPercentageErrorText"]?.value =
          "empty_blood_percentage_error_msg".tr;
      valid = false;
    }
    if (signupControllers["weightController"]?.text.isEmpty ?? true) {
      signupErrorText["weightErrorText"]?.value = "empty_weight_error_msg".tr;
      valid = false;
    }
    if (signupControllers["headSizeController"]?.text.isEmpty ?? true) {
      signupErrorText["headSizeErrorText"]?.value =
          "empty_head_size_error_msg".tr;
      valid = false;
    }
    if (signupControllers["heightController"]?.text.isEmpty ?? true) {
      signupErrorText["heightErrorText"]?.value = "empty_height_error_msg".tr;
      valid = false;
    }
    return valid;
  }

  /// Localized reason the birth date is unusable, or null when it is fine.
  String? _birthDateError(String birthdayText) {
    try {
      MedicalDatesGenerator.parseBirthDate(birthdayText);
      return null;
    } on InvalidBirthDateException catch (e) {
      if (e.reason.contains('future')) {
        return "future_date_of_birth_error_msg".tr;
      }
      if (e.reason.contains('years ago')) {
        return "too_old_date_of_birth_error_msg".tr;
      }
      return "invalid_date_of_birth_error_msg".tr;
    }
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
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: signupControllers["emailController"]?.text.trim() ?? "",
              password:
                  signupControllers["passwordController"]?.text.trim() ?? "");
      if (authResult.user != null) {
        user.uid = authResult.user?.uid ?? "";
        final isUserCreated = await _createUserProfile(user);
        if (!isUserCreated) {
          await authResult.user?.delete();
          AppConstant.alertService
              .showError(message: "SignupController_create_user_failed_msg".tr);
          return;
        }
      }
    } on FirebaseException catch (e) {
      setError(friendlyFirebaseError(e));
    }
  }

  Future<bool> _createUserProfile(UserModel user) async {
    try {
      final generatedVaccines =
          MedicalDatesGenerator.generator(user.birthday ?? '');
      final String datesPath = AppPath.userMedicalDates(user.uid);

      // The profile and the whole generated schedule in one atomic batch,
      // with ids made on the device: no half-created schedule if the
      // connection drops, and no server read-back that hangs offline.
      await AppConstant.fireStoreHelper1.commitSets({
        AppPath.userDoc(user.uid): user.toMap(),
        for (final vaccine in generatedVaccines)
          '$datesPath/${AppConstant.fireStoreHelper1.newDocumentId(datesPath)}':
              vaccine.toMap(),
      });

      SessionManager.uId = user.uid;
      await AppConstant.getStorage.write(StorageKey.isLoginKey, true);
      await AppConstant.getStorage.write(StorageKey.uidKey, user.uid);
      await AppConstant.getStorage
          .write(StorageKey.userNameKey, user.name ?? "");
      await Get.find<HomeController>().fetchUserData();

      final NotificationCoordinator reminders =
          Get.find<NotificationCoordinator>();
      // Asked here, where the user has just created a schedule, so the prompt
      // has visible context. Denial does not block sign-up.
      final bool granted = await reminders.requestPermission();
      // One sync instead of a per-vaccine loop: it goes through the same
      // horizon and cap logic as every other sync, so sign-up cannot schedule
      // all 15 years of reminders at once and hit Android's alarm limit.
      await reminders.syncFromFirestore(
        userId: user.uid,
        userName: user.name ?? "Your baby",
      );
      if (!granted) {
        logger.w('Notification permission denied during sign-up');
      }
      AppConstant.alertService.showAlert(
        AlertModel.success(
          message: "SignupController_create_user_success_msg".tr,
          yesAction: () => Get.toNamed(AppRoutes.mainMenu),
        ),
      );

      setSuccess();
      return true;
    } catch (e) {
      logger.e("❌ Error creating user profile: $e");
      setError("SignupController_create_user_failed_msg".tr);
      return false;
    }
  }
}
