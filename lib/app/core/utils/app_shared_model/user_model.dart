import 'package:baby_vax/app/core/imports/import_library.dart';

class UserModel {
  String uid;
  final String email;
  final String? birthday;
  final String? name;
  final String? height;
  final String? weight;
  final String? bloodPercentage;
  final String? headSize;

  UserModel({
    required this.uid,
    required this.email,
    this.birthday,
    this.name,
    this.height,
    this.weight,
    this.bloodPercentage,
    this.headSize,
  });

  factory UserModel.fromJson(Map<String, dynamic>? json) {
    return UserModel(
      uid: json?["uid"] ?? "",
      email: json?["email"] ?? "",
      birthday: json?["birthday"] ?? "",
      name: json?["name"],
      weight: json?["weight"] ?? "",
      height: json?["height"] ?? "",
      bloodPercentage: json?["bloodPercentage"] ?? "",
      headSize: json?["headSize"] ?? "",
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data["email"] ?? "",
      birthday: data["birthday"] ?? "",
      name: data["name"],
      weight: data["weight"] ?? "",
      height: data["height"] ?? "",
      bloodPercentage: data["bloodPercentage"] ?? "",
      headSize: data["headSize"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "birthday": birthday,
      "name": name,
      "weight": weight,
      "height": height,
      "bloodPercentage": bloodPercentage,
      "headSize": headSize,
    };
  }
}
