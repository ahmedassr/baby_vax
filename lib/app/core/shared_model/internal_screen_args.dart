import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:baby_vax/app/modules/tips/model/tips_model.dart';

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
