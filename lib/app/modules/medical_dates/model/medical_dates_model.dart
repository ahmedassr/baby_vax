import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';

class MedicalDatesModel {
  final String name;
  final String description;
  final String date;
  final MedicalDateStateEnum state;
  final String? uid;

  MedicalDatesModel(
      {required this.name,
      required this.description,
      required this.date,
      required this.state,
      this.uid});

  MedicalDatesModel copyWith({
    String? name,
    String? description,
    String? date,
    MedicalDateStateEnum? state,
    String? uid,
  }) {
    return MedicalDatesModel(
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      state: state ?? this.state,
      uid: uid ?? this.uid,
    );
  }

  factory MedicalDatesModel.fromJson(Map<String, dynamic>? json) {
    return MedicalDatesModel(
        name: json?["name"] ?? "",
        description: json?["description"],
        date: json?["date"] ?? "",
        state: MedicalDateStateEnum.values.byName(json?["state"] ?? ""),
        uid: json?["_id"] ?? "");
  }

  factory MedicalDatesModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalDatesModel(
        name: data["name"],
        description: data["description"],
        date: data["date"],
        state: MedicalDateStateEnum.values.byName(data["state"]),
        uid: data["_id"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "date": date,
      "state": state.name,
      "_id": uid
    };
  }
}
