import '../../../core/imports/import_library.dart';

class TipsModel {
  final String title;
  final String description;
  final String? image;
  final String? id;

  TipsModel(
      {required this.title, required this.description, this.image, this.id});

  // factory TipsModel.fromJson(Map<String, dynamic> json) {
  //   return TipsModel(
  //       title: json["title"],
  //       description: json["description"],
  //       image: json["image"]);
  // }

  factory TipsModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TipsModel(
        title: data["title"],
        description: data["description"],
        image: data["image"],
        id: doc.id);
  }

  Map<String, dynamic> toMap() {
    final data = {"title": title, "description": description};
    if (image != null) {
      data["image"] = image!;
    }
    return data;
  }
}
