import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/app_enum/medical_date_state_enum.dart';

class MedicalDatesModel {
  final String name;
  final String description;
  final DateTime date;
  final String state;
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
    String? state,
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
        state: json?["state"] ?? "",
        id: json?["id"]);
  }

  factory MedicalDatesModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = data["date"];
    DateTime parsedDate = date is Timestamp ? date.toDate() : date;
    return MedicalDatesModel(
        name: data["name"],
        description: data["description"],
        date: parsedDate,
        state: data["state"],
        id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "date": Timestamp.fromDate(date),
      "state": state,
      // "id": id ?? "${name}_$date",
    };
  }
}
