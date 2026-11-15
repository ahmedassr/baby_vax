import '../../../core/imports/import_library.dart';

/// A care tip, authored in the Firebase console (`tips` in Arabic,
/// `tips_en` in English).
class TipsModel {
  final String title;
  final String description;

  /// Optional image URL.
  final String? image;
  final String? id;

  TipsModel(
      {required this.title, required this.description, this.image, this.id});

  /// Tolerant of a document missing a field: a tip with no title shows an
  /// empty title rather than breaking the whole list (v1.0 cast straight to
  /// non-nullable fields).
  factory TipsModel.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final Object? image = data["image"];
    return TipsModel(
        title: (data["title"] as String?) ?? '',
        description: (data["description"] as String?) ?? '',
        image: image is String && image.isNotEmpty ? image : null,
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
