import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:baby_vax/app/modules/tips/model/tips_model.dart';

class InternalScreenArgs {
  MedicalDatesModel? _medicalDate;
  TipsModel? _tip;

  InternalScreenArgs({MedicalDatesModel? medicalDate, TipsModel? tip})
      : _medicalDate = medicalDate,
        _tip = tip;

  MedicalDatesModel? get medicalDate => _medicalDate;

  TipsModel? get tip => _tip;

  set medicalDate(MedicalDatesModel? value) => _medicalDate = value;

  set tip(TipsModel? value) => _tip = value;

  static InternalScreenArgs get fromArgs {
    return AppConstant.argumentService.getArguments<InternalScreenArgs>();
  }
}
