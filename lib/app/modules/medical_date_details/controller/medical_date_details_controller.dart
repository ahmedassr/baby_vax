import 'dart:async';

import 'package:baby_vax/app/core/service/vaccine_state_service.dart';
import 'package:baby_vax/app/core/utils/app_haptics.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';

import '../../../core/imports/import_manger.dart';

/// One dose: what it is, when it is due, and marking it given, skipped, or
/// back to pending.
///
/// v1.0 put the whole screen into a loading state during a change and, on a
/// failure, into an error state that rendered nothing while a dialog opened
/// from a post-frame callback. Now the screen stays put: the action button
/// shows a spinner, and the outcome is a banner on the screen.
class MedicalDateDetailsController extends GetxController {
  MedicalDateDetailsController({
    VaccineStateService? stateService,
    MedicalDatesModel? dose,
    Future<bool> Function(String message)? confirm,
    DateTime Function()? clock,
  })  : _stateService = stateService ??
            VaccineStateService(
              writer: FirestoreDoseStateWriter(),
              reminders: CoordinatorDoseReminders(),
            ),
        _confirm = confirm ?? _dialogConfirm,
        _now = clock ?? DateTime.now,
        _initial = dose ?? InternalScreenArgs.fromArgs.medicalDate;

  final VaccineStateService _stateService;
  final Future<bool> Function(String message) _confirm;
  final DateTime Function() _now;
  final MedicalDatesModel? _initial;

  /// The dose shown; null when the screen was opened without one.
  final Rxn<MedicalDatesModel> dose = Rxn<MedicalDatesModel>();

  final RxBool isSaving = false.obs;

  /// The last change was stored on the phone only ("Saved on this phone. It
  /// will sync when you are back online.").
  final RxBool savedOffline = false.obs;

  final RxnString errorMessage = RxnString();

  /// v1.0 name, kept for callers.
  MedicalDatesModel? get medicalDate => dose.value;

  DateTime get now => _now();

  bool get canMarkCompleted =>
      dose.value != null && VaccineStatePolicy.canMarkCompleted(dose.value!);

  bool get canMarkSkipped =>
      dose.value != null && VaccineStatePolicy.canMarkSkipped(dose.value!);

  bool get canUndo =>
      dose.value != null && VaccineStatePolicy.canUndo(dose.value!);

  @override
  void onInit() {
    super.onInit();
    dose.value = _initial;
  }

  static Future<bool> _dialogConfirm(String message) {
    final Completer<bool> answer = Completer<bool>();
    AppConstant.alertService
        .showAlert(AlertModel.attention(
      message: message,
      yesAction: () => answer.complete(true),
      noAction: () => answer.complete(false),
    ))
        .then((_) {
      // Dismissed by tapping outside: treat as "no".
      if (!answer.isCompleted) answer.complete(false);
    });
    return answer.future;
  }

  /// Marks the dose as given. A dose scheduled after today asks first,
  /// since that is more likely a mis-tap than a dose given early.
  Future<void> onMarkCompleted() async {
    final MedicalDatesModel? d = dose.value;
    if (d == null) return;
    if (VaccineStatePolicy.completionNeedsConfirmation(d, _now())) {
      final bool yes = await _confirm(
          "MedicalDateDetails_confirm_future_completion_msg".trIsolated(
              <String, String>{'date': AppDateFormat.date(d.date)}));
      if (!yes) return;
    }
    await _change(_stateService.markCompleted);
  }

  Future<void> onMarkSkipped() => _change(_stateService.markSkipped);

  Future<void> onUndo() => _change(_stateService.undo);

  Future<void> _change(
    Future<StateChange> Function(MedicalDatesModel dose) action,
  ) async {
    final MedicalDatesModel? d = dose.value;
    if (d == null || isSaving.value) return;

    isSaving.value = true;
    errorMessage.value = null;
    savedOffline.value = false;
    try {
      final StateChange change = await action(d);
      dose.value = change.dose;
      savedOffline.value = change.outcome == WriteOutcome.pendingSync;
      AppHaptics.confirm();
      _refreshLists();
    } catch (e, s) {
      logger.w('Dose state change failed', error: e, stackTrace: s);
      errorMessage.value =
          "MedicalDateDetailsController_state_update_failed_msg".tr;
    } finally {
      isSaving.value = false;
    }
  }

  /// The schedule list and the home card show this dose too. Not awaited:
  /// offline, these reads come from the local cache, which already has the
  /// change.
  void _refreshLists() {
    if (Get.isRegistered<MedicalDatesController>()) {
      Get.find<MedicalDatesController>().fetchMedicalDates();
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().fetchUserData();
    }
  }
}
