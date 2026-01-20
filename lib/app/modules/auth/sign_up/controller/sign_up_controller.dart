import 'package:baby_vax/app/core/utils/medical_dates_generator.dart';
import 'package:intl/intl.dart';
import '../../../../core/imports/import_manger.dart';
import '../../../../core/notification/data/onesignal_notification_provider.dart';
import '../../../main/controller/main_controller.dart';

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

  @override
  void onInit() {
    super.onInit();
    setSuccess();
    signupControllers["birthdayController"]?.text =
        DateFormat("yyyy-MM-dd HH:mm:ss").format(selectedBirthday.value);
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
        DateFormat("yyyy-MM-dd HH:mm:ss").format(selectedBirthday.value);
  }

  bool isValidate() {
    bool valid = true;
    for (var text in signupErrorText.values) {
      text.value = "";
    }
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
          AppConstant.alertService.showError(
              message: "Failed to create user profile. Please try again.");
          return;
        }
      }
    } on FirebaseException catch (e) {
      setError(getFriendlyErrorMessage(e.toString()));
    }
  }

  Future<bool> _createUserProfile(UserModel user) async {
    try {
      await AppConstant.fireStoreHelper
          .createUser(uid: user.uid, userDate: user.toMap());

      logger.d("${user.birthday}");

      final vaccines = MedicalDatesGenerator.generator(user.birthday ?? '');
      await AppConstant.fireStoreHelper.createDynamicPath<MedicalDatesModel>(
        path: ["users", user.uid, "medical_dates"],
        data: vaccines,
        toMap: (e) => e.toMap(),
      );

      // Notification Schedule
      for (var vaccine in vaccines) {
        final date = vaccine.date;
        if (date.isAfter(DateTime.now())) {
          final vaccineId = "${vaccine.name}_$date";
          await Get.find<NotificationCoordinator>().scheduleVaccine(
            vaccineId: vaccineId,
            userName: user.name ?? "Your baby",
            vaccineName: vaccine.name,
            date: date,
          );
        }
      }
      SessionManager.uId = user.uid;
      AppConstant.getStorage.write(AppConstant.isLoginKey, true);
      AppConstant.getStorage.write(AppConstant.uidKey, user.uid);
      await AppConstant.fireStoreHelper.updateFcmToken();
      await Get.find<OneSingleNotificationProvider>()
          .setUser(SessionManager.uId);
      await Get.find<MainController>().fetchUserData();
      AppConstant.alertService.showAlert(
        AlertModel.success(
          message: "User created successfully.",
          yesAction: () => Get.toNamed(AppRoutes.mainMenu),
        ),
      );

      setSuccess();
      return true;
    } catch (e) {
      logger.e("❌ Error creating user profile: $e");
      setError("Failed to create user profile. Please try again.");
      return false;
    }
  }
}
