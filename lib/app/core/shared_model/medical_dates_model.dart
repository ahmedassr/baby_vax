import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';

class MedicalDatesModel {
  final String name;
  final String description;
  final String date;
  final MedicalDateStateEnum state;

  MedicalDatesModel(
      {required this.name,
      required this.description,
      required this.date,
      required this.state});

  factory MedicalDatesModel.fromJson(Map<String, dynamic>? json) {
    return MedicalDatesModel(
        name: json?["name"] ?? "",
        description: json?["description"],
        date: json?["date"] ?? "",
        state: MedicalDateStateEnum.values.byName(json?["state"] ?? ""));
  }

  factory MedicalDatesModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalDatesModel(
        name: data["name"],
        description: data["description"],
        date: data["date"],
        state: MedicalDateStateEnum.values.byName(data["state"]));
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "data": date,
      "state": state.name
    };
  }
}
