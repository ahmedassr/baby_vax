import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/core/service/medical_dates_generator.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/core/utils/validators.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

/// Edits the baby's profile: name, date of birth, sex and measurements.
///
/// v1.0 let the email be edited but only wrote it to Firestore, never to
/// Firebase Auth, so the profile silently disagreed with the sign-in email.
/// It is read-only now. v1.0 also had no validation and saved a "-" as the
/// name when there was none.
///
/// Changing the date of birth moves every generated dose to match (after
/// asking), since the schedule was built from it; states are kept.
class EditUserController extends GetxController {
  EditUserController({
    UserModel? user,
    Future<WriteOutcome> Function(UserModel user)? save,
    Future<void> Function(DateTime birthday)? rebaseSchedule,
    Future<bool> Function(String message)? confirm,
    DateTime Function()? clock,
  })  : _original = user ?? InternalScreenArgs.fromArgs.user,
        _save = save ?? _firestoreSave,
        _rebaseSchedule = rebaseSchedule ?? _firestoreRebase,
        _confirm = confirm ?? _dialogConfirm,
        _now = clock ?? DateTime.now;

  final UserModel? _original;
  final Future<WriteOutcome> Function(UserModel) _save;
  final Future<void> Function(DateTime) _rebaseSchedule;
  final Future<bool> Function(String) _confirm;
  final DateTime Function() _now;

  final TextEditingController name = TextEditingController();
  final TextEditingController birthday = TextEditingController();
  final TextEditingController weight = TextEditingController();
  final TextEditingController height = TextEditingController();
  final TextEditingController headSize = TextEditingController();
  final TextEditingController blood = TextEditingController();

  final Rxn<DateTime> selectedBirthday = Rxn<DateTime>();
  final RxnString sex = RxnString();

  final RxnString nameError = RxnString();
  final RxnString birthdayError = RxnString();
  final RxnString weightError = RxnString();
  final RxnString heightError = RxnString();
  final RxnString headSizeError = RxnString();
  final RxnString bloodError = RxnString();
  final RxnString saveError = RxnString();
  final RxBool isSaving = false.obs;

  /// The profile being edited; null when the screen was opened without one.
  UserModel? get original => _original;

  String get email => _original?.email ?? '';

  DateTime? get _originalBirthday {
    final String b = _original?.birthday ?? '';
    final DateTime? d = b.isEmpty ? null : DateTime.tryParse(b);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  bool get birthdayChanged =>
      selectedBirthday.value != null &&
      selectedBirthday.value != _originalBirthday;

  @override
  void onInit() {
    super.onInit();
    final UserModel? u = _original;
    if (u == null) return;
    name.text = (u.name ?? '').trim() == '-' ? '' : (u.name ?? '').trim();
    weight.text = u.weight ?? '';
    height.text = u.height ?? '';
    headSize.text = u.headSize ?? '';
    blood.text = u.bloodPercentage ?? '';
    sex.value = u.sex;
    final DateTime? b = _originalBirthday;
    if (b != null) {
      selectedBirthday.value = b;
      birthday.text = AppDateFormat.date(b);
    }
  }

  void setBirthday(DateTime picked) {
    selectedBirthday.value = DateTime(picked.year, picked.month, picked.day);
    birthday.text = AppDateFormat.date(selectedBirthday.value!);
    birthdayError.value = null;
  }

  void setSex(String value) {
    sex.value = value;
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

  bool _validate() {
    nameError.value =
        Validators.requiredText(name.text, "empty_name_error_msg");
    final DateTime? b = selectedBirthday.value;
    if (b != null) {
      try {
        MedicalDatesGenerator.parseBirthDate(
            SignupController.storageFormat.format(b),
            now: _now());
        birthdayError.value = null;
      } on InvalidBirthDateException {
        birthdayError.value = "invalid_date_of_birth_error_msg".tr;
      }
    }
    weightError.value = Validators.optionalMeasurement(weight.text,
        min: SignupController.weightBounds.min,
        max: SignupController.weightBounds.max);
    heightError.value = Validators.optionalMeasurement(height.text,
        min: SignupController.heightBounds.min,
        max: SignupController.heightBounds.max);
    headSizeError.value = Validators.optionalMeasurement(headSize.text,
        min: SignupController.headBounds.min,
        max: SignupController.headBounds.max);
    bloodError.value = Validators.optionalMeasurement(blood.text,
        min: SignupController.bloodBounds.min,
        max: SignupController.bloodBounds.max);
    return <RxnString>[
      nameError,
      birthdayError,
      weightError,
      heightError,
      headSizeError,
      bloodError
    ].every((e) => e.value == null);
  }

  /// The profile as it will be saved.
  UserModel buildUser() {
    final UserModel u = _original!;
    final DateTime? b = selectedBirthday.value;
    return UserModel(
      uid: u.uid.isNotEmpty ? u.uid : (SessionManager.signedInUid ?? ''),
      email: u.email,
      birthday:
          b == null ? u.birthday : SignupController.storageFormat.format(b),
      name: name.text.trim(),
      weight: SignupController.normalised(weight.text),
      height: SignupController.normalised(height.text),
      headSize: SignupController.normalised(headSize.text),
      bloodPercentage: SignupController.normalised(blood.text),
      sex: sex.value,
    );
  }

  Future<void> updateUser() async {
    if (_original == null || isSaving.value) return;
    saveError.value = null;
    if (!_validate()) return;

    final bool rebase = birthdayChanged;
    if (rebase) {
      final bool yes = await _confirm("EditUser_birthday_change_confirm".tr);
      if (!yes) return;
    }

    isSaving.value = true;
    try {
      final UserModel updated = buildUser();
      final WriteOutcome outcome = await _save(updated);
      if (rebase) await _rebaseSchedule(selectedBirthday.value!);
      await AppConstant.getStorage
          .write(StorageKey.userNameKey, updated.name ?? '');
      AppHaptics.confirm();
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchUserData();
      }
      if (Get.isRegistered<MedicalDatesController>()) {
        Get.find<MedicalDatesController>().fetchMedicalDates();
      }
      Get.back(result: outcome);
      Get.showSnackbar(GetSnackBar(
        message: outcome == WriteOutcome.pendingSync
            ? "saved_offline_msg".tr
            : "EditUser_saved_msg".tr,
        duration: const Duration(seconds: 3),
      ));
    } catch (e, s) {
      logger.w('Profile update failed', error: e, stackTrace: s);
      saveError.value = "EditUserController_update_user_failed".tr;
    } finally {
      isSaving.value = false;
    }
  }

  // ---- real implementations ----------------------------------------------

  /// Returns once the change is stored on the device. Offline it does not
  /// wait for the server; Firestore sends it when the phone reconnects.
  static Future<WriteOutcome> _firestoreSave(UserModel user) =>
      AppConstant.fireStoreHelper1
          .updateData(path: AppPath.currentUserDoc, data: user.toMap());

  /// Moves the generated doses to the corrected birth date in one batch,
  /// then rebuilds the reminders from the new dates.
  static Future<void> _firestoreRebase(DateTime birthday) async {
    final String? uid = SessionManager.signedInUid;
    if (uid == null) return;
    final String path = AppPath.userMedicalDates(uid);
    final List<MedicalDatesModel> doses = await AppConstant.fireStoreHelper1
        .getCollection(path: path, fromDoc: MedicalDatesModel.fromDocument);
    final List<MedicalDatesModel> moved =
        MedicalDatesGenerator.rebase(doses, birthday);
    if (moved.isEmpty) return;
    await AppConstant.fireStoreHelper1
        .commitSets(<String, Map<String, dynamic>>{
      for (final MedicalDatesModel d in moved) '$path/${d.id}': d.toMap(),
    });
    await Get.find<NotificationCoordinator>().syncFromFirestore(
      userId: uid,
      userName: reminderChildName(
          AppConstant.getStorage.read(StorageKey.userNameKey)),
    );
  }

  static Future<bool> _dialogConfirm(String message) async {
    final bool? yes = await Get.dialog<bool>(AlertDialog(
      icon: const Icon(Icons.event_repeat_rounded),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text("cancel".tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: Text("EditUser_birthday_change_yes".tr),
        ),
      ],
    ));
    return yes ?? false;
  }

  @override
  void onClose() {
    for (final TextEditingController c in <TextEditingController>[
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
