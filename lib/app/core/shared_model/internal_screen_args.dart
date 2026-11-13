import 'package:baby_vax/app/core/imports/import_manger.dart';

class InternalScreenArgs {
  final MedicalDatesModel? medicalDate;
  final TipsModel? tip;
  final UserModel? user;

  InternalScreenArgs({
    this.medicalDate,
    this.tip,
    this.user,
  });

  /// The arguments the previous screen set, or empty ones.
  static InternalScreenArgs get fromArgs =>
      AppConstant.argumentService.getArguments<InternalScreenArgs>() ??
      InternalScreenArgs();
}
