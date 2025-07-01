import 'package:baby_vax/app/config/constant/app_constant.dart';
import 'package:baby_vax/app/modules/medical_dates/model/medical_dates_model.dart';
import 'package:baby_vax/app/modules/tips/model/tips_model.dart';

class InternalScreenArgs {
  MedicalDatesModel? _medicalDates;
  TipsModel? _tips;

  InternalScreenArgs({MedicalDatesModel? medicalDate, TipsModel? tips})
      : _medicalDates = medicalDate,
        _tips = tips;

  MedicalDatesModel? get medicalDates => _medicalDates;

  TipsModel? get tips => _tips;

  set medicalDates(MedicalDatesModel? value) => _medicalDates = value;

  set tips(TipsModel? value) => _tips = value;

  static InternalScreenArgs get fromArgs {
    return AppConstant.argumentService.getArguments<InternalScreenArgs>();
  }
}
