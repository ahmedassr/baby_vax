import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/modules/home/controller/home_controller.dart';
import 'package:baby_vax/app/core/service/vaccine_state_service.dart';

import '../../../core/imports/import_manger.dart';

class MedicalDateDetailsController extends GetxController
    with StateMixin, StateMixinHelper {
  MedicalDateDetailsController({VaccineStateService? stateService})
      : _stateService = stateService ??
            VaccineStateService(
              writer: FirestoreDoseStateWriter(),
              reminders: CoordinatorDoseReminders(),
            );

  final VaccineStateService _stateService;

  MedicalDatesModel? medicalDate;
  final args = InternalScreenArgs.fromArgs.medicalDate;

  bool get canMarkCompleted =>
      medicalDate != null && VaccineStatePolicy.canMarkCompleted(medicalDate!);

  bool get canMarkSkipped =>
      medicalDate != null && VaccineStatePolicy.canMarkSkipped(medicalDate!);

  bool get canUndo =>
      medicalDate != null && VaccineStatePolicy.canUndo(medicalDate!);

  @override
  void onInit() {
    super.onInit();
    initializeMedicalDateArgument();
    setSuccess();
  }

  void initializeMedicalDateArgument() {
    if (args != null) {
      medicalDate = args;
    } else {
      setError("MedicalDateDetailsController_missing_medical_dates_msg".tr);
    }
  }

  Future fetchDate() async {
    setLoading();
    try {
      final data = await AppConstant.fireStoreHelper1.getDocument(
          path:
              "${AppPath.userMedicalDates(SessionManager.signedInUid ?? "")}/${medicalDate?.id}",
          fromDoc: MedicalDatesModel.fromDocument);
      if (data == null) {
        setEmpty();
      } else {
        medicalDate = data;
        setSuccess();
      }
    } catch (_) {
      setError("MedicalDateDetailsController_fetch_failed_msg".tr);
    }
  }

  /// Marks the dose as given. A dose scheduled after today asks first.
  void onMarkCompleted() {
    final MedicalDatesModel? dose = medicalDate;
    if (dose == null) return;

    if (VaccineStatePolicy.completionNeedsConfirmation(dose, DateTime.now())) {
      AppConstant.alertService.showAlert(AlertModel.attention(
        message: "MedicalDateDetails_confirm_future_completion_msg".trParams(
          <String, String>{'date': AppDateFormat.date(dose.date)},
        ),
        yesAction: () => _change(_stateService.markCompleted),
        noAction: () {},
      ));
      return;
    }
    _change(_stateService.markCompleted);
  }

  void onMarkSkipped() => _change(_stateService.markSkipped);

  void onUndo() => _change(_stateService.undo);

  Future<void> _change(
    Future<StateChange> Function(MedicalDatesModel dose) action,
  ) async {
    final MedicalDatesModel? dose = medicalDate;
    if (dose == null) return;

    setLoading();
    try {
      final StateChange change = await action(dose);
      medicalDate = change.dose;
      setSuccess();
      _refreshLists();
      if (change.outcome == WriteOutcome.pendingSync) {
        AppConstant.alertService
            .showAlert(AlertModel.success(message: "saved_offline_msg".tr));
      }
    } catch (e, s) {
      logger.w('Dose state change failed', error: e, stackTrace: s);
      setError("MedicalDateDetailsController_state_update_failed_msg".tr);
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
