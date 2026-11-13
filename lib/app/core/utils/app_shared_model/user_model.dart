import 'package:baby_vax/app/core/imports/import_library.dart';

/// The signed-in parent's profile, which in this app is also the child's
/// profile (one account, one child).
///
/// Measurements are strings for compatibility with v1.0 documents. v1.1
/// writes them normalised ("3.4", Western digits); the growth tracker keeps
/// the dated history in `users/{uid}/measurements` and copies the newest
/// values here so the home screen and older builds keep working.
class UserModel {
  String uid;
  final String email;

  /// ISO date, `yyyy-MM-dd` (older documents may carry a time part).
  final String? birthday;
  final String? name;
  final String? height;
  final String? weight;
  final String? bloodPercentage;
  final String? headSize;

  /// `female` or `male`, or null for v1.0 profiles that never recorded it.
  /// Needed only for the WHO growth percentiles.
  final String? sex;

  UserModel({
    required this.uid,
    required this.email,
    this.birthday,
    this.name,
    this.height,
    this.weight,
    this.bloodPercentage,
    this.headSize,
    this.sex,
  });

  /// The two values the rules accept.
  static const Set<String> allowedSexes = <String>{'female', 'male'};

  static String? _sex(Object? value) =>
      value is String && allowedSexes.contains(value) ? value : null;

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
      sex: _sex(json?["sex"]),
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return UserModel.fromJson(data)..uid = doc.id;
  }

  UserModel copyWith({
    String? email,
    String? birthday,
    String? name,
    String? height,
    String? weight,
    String? bloodPercentage,
    String? headSize,
    String? sex,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      birthday: birthday ?? this.birthday,
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodPercentage: bloodPercentage ?? this.bloodPercentage,
      headSize: headSize ?? this.headSize,
      sex: sex ?? this.sex,
    );
  }

  /// The Firestore document. `sex` is only written when known, so an edit
  /// from a build that does not know about it never clears it.
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
      if (sex != null) "sex": sex,
    };
  }
}
