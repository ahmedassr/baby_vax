class UpcomingVaxModel {
  String? name;
  DateTime? date;

  UpcomingVaxModel({this.name, this.date});

  UpcomingVaxModel.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    date = json['date'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'date': date};
  }
}
