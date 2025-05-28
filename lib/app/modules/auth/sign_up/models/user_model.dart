class UserModel {
  String uid;
  final String email;
  final String birthday;
  final String? name;
  final String? height;
  final String? weight;
  final String? bloodPercentage;
  final String? headSize;

  UserModel({
    required this.uid,
    required this.email,
    required this.birthday,
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
      weight: json?["weight"] ?? 0,
      height: json?["height"] ?? 0,
      bloodPercentage: json?["bloodPercentage"] ?? 0,
      headSize: json?["headSize"] ?? 0,
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
