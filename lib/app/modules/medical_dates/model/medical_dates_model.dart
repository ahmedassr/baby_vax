import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';

class MedicalDatesModel {
  final String name;
  final String description;
  final DateTime date;
  final MedicalDateStateEnum state;
  final String? id;

  MedicalDatesModel(
      {required this.name,
      required this.description,
      required this.date,
      required this.state,
      this.id});

  MedicalDatesModel copyWith({
    String? name,
    String? description,
    DateTime? date,
    MedicalDateStateEnum? state,
    String? id,
  }) {
    return MedicalDatesModel(
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      state: state ?? this.state,
      id: id ?? this.id,
    );
  }

  factory MedicalDatesModel.fromJson(Map<String, dynamic>? json) {
    final date = json?["date"];
    DateTime parsedDate = date is Timestamp ? date.toDate() : date;
    return MedicalDatesModel(
        name: json?["name"] ?? "",
        description: json?["description"],
        date: parsedDate,
        state: MedicalDateStateEnum.values.byName(json?["state"] ?? ""),
        id: json?["id"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "date": Timestamp.fromDate(date),
      "state": state.name,
      "id": id ?? "${name}_$date",
    };
  }
}
