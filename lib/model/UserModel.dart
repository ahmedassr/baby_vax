class UserModel {
  String? email;
  String? name;
  String? birthDate;
  int? weight;
  int? bloodPercent;
  int? height;
  int? headCircle;
  String? uId;
  String? token;

  UserModel({
    this.name,
    this.email,
    this.birthDate,
    this.bloodPercent,
    this.weight,
    this.headCircle,
    this.height,
    this.uId,
    this.token,
  });

  UserModel.fromJson(Map<String, dynamic>? json) {
    email = json?['email'] ?? '';
    name = json?['name'] ?? '';
    birthDate = json?['birthDate'] ?? '';
    weight = json?['weight'] ?? '';
    bloodPercent = json?['bloodPercent'] ?? '';
    height = json?['height'] ?? '';
    headCircle = json?['headCircle'] ?? '';
    uId = json?['uId'] ?? '';
    token = json?['token'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'birthDate': birthDate,
      'uId': uId,
      'weight': weight,
      'bloodPercent': bloodPercent,
      'headCircle': headCircle,
      'height': height,
      'token': token ?? '',
    };
  }
}
