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

  static InternalScreenArgs get fromArgs {
    return AppConstant.argumentService.getArguments<InternalScreenArgs>();
  }
}
