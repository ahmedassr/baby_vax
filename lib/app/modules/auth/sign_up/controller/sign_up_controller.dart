import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/core/utils/validators.dart';
import 'package:intl/intl.dart';

import '../../../../config/constant/app_path.dart';
import '../../../../core/imports/import_manger.dart';
import '../../../home/controller/home_controller.dart';

/// The five sign-up steps, in order.
enum SignupStep { account, baby, measurements, reminders, summary }

/// The baby's sex as stored in the profile. Only these two values pass the
/// Firestore rules; the WHO growth standards are published for each.
class BabySex {
  const BabySex._();

  static const String female = 'female';
  static const String male = 'male';
}

/// Whether the parent has been asked for the notification permission yet.
enum ReminderPermission { notAsked, granted, denied }

/// Sign-up as a five-step flow: account, baby, measurements (optional),
/// reminders, summary.
///
/// v1.0 was one long form with eight required fields — including the
/// haemoglobin figure, which many parents do not know — validated only on
/// submit. Here each step validates before moving on, values survive going
/// back, and a failure from the server lands on the step that owns it: an
/// email that is already registered sends the parent back to step 1 with
/// the message under the email field.
class SignupController extends GetxController {
  SignupController({
    Future<String> Function(String email, String password)? createAccount,
    Future<void> Function(UserModel user, List<MedicalDatesModel> schedule)?
        saveProfile,
    Future<void> Function()? rollbackAccount,
    Future<void> Function(UserModel user)? onCreated,
    Future<bool> Function()? requestPermission,
    DateTime Function()? clock,
  })  : _createAccount = createAccount ?? _firebaseCreateAccount,
        _saveProfile = saveProfile ?? _firestoreSaveProfile,
        _rollbackAccount = rollbackAccount ?? _firebaseRollback,
        _onCreated = onCreated ?? _prepareSession,
        _requestPermission = requestPermission ?? _coordinatorPermission,
        _now = clock ?? DateTime.now;

  final Future<String> Function(String, String) _createAccount;
  final Future<void> Function(UserModel, List<MedicalDatesModel>) _saveProfile;
  final Future<void> Function() _rollbackAccount;
  final Future<void> Function(UserModel) _onCreated;
  final Future<bool> Function() _requestPermission;
  final DateTime Function() _now;

  // ---- state -----------------------------------------------------------

  final Rx<SignupStep> step = SignupStep.account.obs;

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController birthday = TextEditingController();
  final TextEditingController weight = TextEditingController();
  final TextEditingController height = TextEditingController();
  final TextEditingController headSize = TextEditingController();
  final TextEditingController blood = TextEditingController();

  /// A calendar day, or null until picked. The schedule only depends on the
  /// date of birth, so there is no time part.
  final Rxn<DateTime> selectedBirthday = Rxn<DateTime>();

  /// [BabySex.female] or [BabySex.male], or null until chosen.
  final RxnString sex = RxnString();

  final Rx<ReminderPermission> reminders = ReminderPermission.notAsked.obs;

  final RxnString emailError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString nameError = RxnString();
  final RxnString birthdayError = RxnString();
  final RxnString sexError = RxnString();
  final RxnString weightError = RxnString();
  final RxnString heightError = RxnString();
  final RxnString headSizeError = RxnString();
  final RxnString bloodError = RxnString();

  /// A failure on the final step that is not about any one field: offline,
  /// too many attempts, the profile could not be written.
  final RxnString submitError = RxnString();

  final RxBool isSubmitting = false.obs;
  final RxBool isRequestingPermission = false.obs;

  /// Plausibility bounds for the optional measurements. They catch typos
  /// (3400 for 3.4 kg, a height in metres) and are deliberately wide: the
  /// schedule covers children up to 18. They are not reference ranges and
  /// are never shown as such.
  static const ({double min, double max}) weightBounds = (min: 0.3, max: 150);
  static const ({double min, double max}) heightBounds = (min: 20, max: 220);
  static const ({double min, double max}) headBounds = (min: 20, max: 70);
  static const ({double min, double max}) bloodBounds = (min: 1, max: 30);

  /// Stored form of the birthday: ISO date, fixed ASCII digits whatever the
  /// UI language. The form field shows [AppDateFormat.date] instead.
  static final DateFormat storageFormat = DateFormat('yyyy-MM-dd', 'en');

  String get birthdayForStorage {
    final DateTime? d = selectedBirthday.value;
    return d == null ? '' : storageFormat.format(d);
  }

  int get stepIndex => step.value.index;
  bool get isFirstStep => step.value == SignupStep.account;
  bool get isLastStep => step.value == SignupStep.summary;

  // ---- navigation --------------------------------------------------------

  /// Validates the current step and moves to the next one. On the last step
  /// this creates the account.
  Future<void> next() async {
    if (isLastStep) return submit();
    if (!validateStep(step.value)) return;
    AppHaptics.selection();
    step.value = SignupStep.values[stepIndex + 1];
  }

  /// Goes back one step without validating. Returns false on the first
  /// step, so the caller can leave the screen instead.
  bool back() {
    if (isFirstStep) return false;
    AppHaptics.selection();
    submitError.value = null;
    step.value = SignupStep.values[stepIndex - 1];
    return true;
  }

  /// Jumps to an earlier step from the summary's "Edit" links.
  void goTo(SignupStep target) {
    if (target.index >= stepIndex) return;
    submitError.value = null;
    step.value = target;
  }

  /// Clears the optional measurements and moves on.
  void skipMeasurements() {
    for (final TextEditingController c in [weight, height, headSize, blood]) {
      c.clear();
    }
    for (final RxnString e in [
      weightError,
      heightError,
      headSizeError,
      bloodError
    ]) {
      e.value = null;
    }
    step.value = SignupStep.reminders;
  }

  // ---- validation --------------------------------------------------------

  /// Validates [s], setting the field errors. True when the step is valid.
  bool validateStep(SignupStep s) {
    switch (s) {
      case SignupStep.account:
        emailError.value = Validators.email(email.text);
        passwordError.value = Validators.newPassword(password.text.trim());
        return emailError.value == null && passwordError.value == null;
      case SignupStep.baby:
        nameError.value =
            Validators.requiredText(name.text, "empty_name_error_msg");
        birthdayError.value = _birthDateError();
        sexError.value = sex.value == null ? "empty_sex_error_msg".tr : null;
        return nameError.value == null &&
            birthdayError.value == null &&
            sexError.value == null;
      case SignupStep.measurements:
        weightError.value = Validators.optionalMeasurement(weight.text,
            min: weightBounds.min, max: weightBounds.max);
        heightError.value = Validators.optionalMeasurement(height.text,
            min: heightBounds.min, max: heightBounds.max);
        headSizeError.value = Validators.optionalMeasurement(headSize.text,
            min: headBounds.min, max: headBounds.max);
        bloodError.value = Validators.optionalMeasurement(blood.text,
            min: bloodBounds.min, max: bloodBounds.max);
        return weightError.value == null &&
            heightError.value == null &&
            headSizeError.value == null &&
            bloodError.value == null;
      case SignupStep.reminders:
      case SignupStep.summary:
        return true;
    }
  }

  /// Localized reason the birth date is unusable, or null when it is fine.
  ///
  /// Checked here rather than letting the generator throw mid-sign-up,
  /// after the Auth user has already been created.
  String? _birthDateError() {
    if (selectedBirthday.value == null) {
      return "empty_date_of_birth_error_msg".tr;
    }
    try {
      MedicalDatesGenerator.parseBirthDate(birthdayForStorage, now: _now());
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

  // ---- inputs ------------------------------------------------------------

  void setBirthday(DateTime picked) {
    selectedBirthday.value = DateTime(picked.year, picked.month, picked.day);
    birthday.text = AppDateFormat.date(selectedBirthday.value!);
    birthdayError.value = null;
  }

  void setSex(String value) {
    sex.value = value;
    sexError.value = null;
    AppHaptics.selection();
  }

  Future<void> selectBirthday(BuildContext context) async {
    final DateTime today = _now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthday.value ?? today,
      firstDate: MedicalDatesGenerator.addMonths(
          today, -MedicalDatesGenerator.maxAgeYears * 12),
      lastDate: today,
      helpText: "date_of_birth_label".tr,
    );
    if (picked != null) setBirthday(picked);
  }

  /// Asks for the OS notification permission, from the reminders step,
  /// after the parent has read why. Declining is fine and says so.
  Future<void> askForReminders() async {
    if (isRequestingPermission.value) return;
    isRequestingPermission.value = true;
    try {
      final bool granted = await _requestPermission();
      reminders.value =
          granted ? ReminderPermission.granted : ReminderPermission.denied;
    } catch (e, s) {
      logger.w('Notification permission request failed',
          error: e, stackTrace: s);
      reminders.value = ReminderPermission.denied;
    } finally {
      isRequestingPermission.value = false;
    }
  }

  /// A measurement as stored: normalised to Western digits and a dot ("3,4"
  /// and "٣٫٤" both become "3.4"), or empty.
  static String normalised(String raw) {
    final double? n = Validators.parseDecimal(raw);
    if (n == null) return '';
    return n == n.roundToDouble() ? n.toStringAsFixed(0) : '$n';
  }

  /// The profile this sign-up will write.
  UserModel buildUser(String uid) => UserModel(
        uid: uid,
        email: email.text.trim(),
        birthday: birthdayForStorage,
        name: name.text.trim(),
        height: normalised(height.text),
        weight: normalised(weight.text),
        headSize: normalised(headSize.text),
        bloodPercentage: normalised(blood.text),
        sex: sex.value,
      );

  // ---- submit ------------------------------------------------------------

  /// Creates the Auth user, then the profile and the whole schedule in one
  /// batch. If the profile cannot be written the Auth user is deleted again,
  /// so a retry does not hit "email already in use".
  Future<void> submit() async {
    if (isSubmitting.value) return;
    submitError.value = null;

    // Re-check every step: a value could have been cleared after Next.
    for (final SignupStep s in SignupStep.values) {
      if (!validateStep(s)) {
        step.value = s;
        return;
      }
    }

    isSubmitting.value = true;
    String? uid;
    try {
      uid = await _createAccount(email.text.trim(), password.text.trim());
    } on FirebaseAuthException catch (e) {
      isSubmitting.value = false;
      _routeAuthError(e);
      return;
    } catch (e) {
      isSubmitting.value = false;
      submitError.value = friendlyFirebaseError(e);
      return;
    }

    final UserModel user = buildUser(uid);
    try {
      final List<MedicalDatesModel> schedule =
          MedicalDatesGenerator.generator(user.birthday ?? '', now: _now());
      await _saveProfile(user, schedule);
    } catch (e, s) {
      logger.e('Creating the profile failed', error: e, stackTrace: s);
      try {
        await _rollbackAccount();
      } catch (e2) {
        logger.w('Rolling back the Auth user failed', error: e2);
      }
      isSubmitting.value = false;
      submitError.value = e is FirebaseException
          ? friendlyFirebaseError(e)
          : "SignupController_create_user_failed_msg".tr;
      return;
    }

    try {
      await _onCreated(user);
    } catch (e, s) {
      // The account and schedule exist; a reminder or cache failure here
      // must not strand the parent on the sign-up screen.
      logger.w('Post-sign-up setup failed', error: e, stackTrace: s);
    }
    isSubmitting.value = false;
    AppHaptics.confirm();
    Get.offAllNamed(AppRoutes.mainMenu);
  }

  /// Puts an Auth error on the step and field it is about.
  void _routeAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
      case 'invalid-email':
        step.value = SignupStep.account;
        emailError.value = friendlyFirebaseError(e);
      case 'weak-password':
        step.value = SignupStep.account;
        passwordError.value = friendlyFirebaseError(e);
      default:
        // Offline, too many requests: stay on the summary with a retry.
        submitError.value = friendlyFirebaseError(e);
    }
  }

  // ---- real implementations ----------------------------------------------

  static Future<String> _firebaseCreateAccount(
      String email, String password) async {
    final UserCredential result = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final String? uid = result.user?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(code: 'unknown');
    }
    return uid;
  }

  /// The profile and the whole generated schedule in one atomic batch, with
  /// ids made on the device: no half-created schedule if the connection
  /// drops, and no server read-back that hangs offline.
  static Future<void> _firestoreSaveProfile(
      UserModel user, List<MedicalDatesModel> schedule) async {
    final String datesPath = AppPath.userMedicalDates(user.uid);
    await AppConstant.fireStoreHelper1.commitSets({
      AppPath.userDoc(user.uid): user.toMap(),
      for (final MedicalDatesModel dose in schedule)
        '$datesPath/${AppConstant.fireStoreHelper1.newDocumentId(datesPath)}':
            dose.toMap(),
    });
  }

  static Future<void> _firebaseRollback() async {
    await FirebaseAuth.instance.currentUser?.delete();
  }

  static Future<bool> _coordinatorPermission() =>
      Get.find<NotificationCoordinator>().requestPermission();

  static Future<void> _prepareSession(UserModel user) async {
    SessionManager.uId = user.uid;
    await AppConstant.getStorage.write(StorageKey.isLoginKey, true);
    await AppConstant.getStorage.write(StorageKey.uidKey, user.uid);
    await AppConstant.getStorage.write(StorageKey.userNameKey, user.name ?? "");
    // A parent who signs up has just seen the introduction or skipped it.
    await AppConstant.getStorage.write(StorageKey.hasSeenOnboardingKey, true);
    await Get.find<HomeController>().fetchUserData();
    // One sync instead of a per-dose loop: it goes through the same horizon
    // and cap logic as every other sync, so sign-up cannot schedule all 15
    // years of reminders at once and hit Android's alarm limit.
    await Get.find<NotificationCoordinator>().syncFromFirestore(
      userId: user.uid,
      userName: reminderChildName(user.name),
    );
  }

  @override
  void onClose() {
    for (final TextEditingController c in [
      email,
      password,
      name,
      birthday,
      weight,
      height,
      headSize,
      blood
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
