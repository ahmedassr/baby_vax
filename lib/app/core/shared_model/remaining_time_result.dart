import 'package:baby_vax/app/core/values/app_enum/vaccination_time_status_enum.dart';

class RemainingTimeResult{
  final VaccinationTimeStatusEnum status;
  final int? value;
  RemainingTimeResult({required this.status, this.value});
}