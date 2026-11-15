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

  /// v1.1 health profile, all optional, shown in the Health tab and on the
  /// vaccination card. Free text as the parent writes it.
  final String? allergies;
  final String? conditions;

  /// One of [bloodTypes], or null when not known.
  final String? bloodType;
  final String? emergencyContact;

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
    this.allergies,
    this.conditions,
    this.bloodType,
    this.emergencyContact,
  });

  /// The blood types the rules accept.
  static const List<String> bloodTypes = <String>[
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' //
  ];

  /// Health-profile field names, as stored.
  static const List<String> healthFields = <String>[
    'allergies', 'conditions', 'bloodType', 'emergencyContact' //
  ];

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Whether any health-profile field is filled in.
  bool get hasHealthProfile =>
      allergies != null ||
      conditions != null ||
      bloodType != null ||
      emergencyContact != null;

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
      allergies: _text(json?["allergies"]),
      conditions: _text(json?["conditions"]),
      bloodType:
          bloodTypes.contains(json?["bloodType"]) ? json!["bloodType"] : null,
      emergencyContact: _text(json?["emergencyContact"]),
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
    String? allergies,
    String? conditions,
    String? bloodType,
    String? emergencyContact,
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
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      bloodType: bloodType ?? this.bloodType,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  /// The Firestore document. `sex` and the health profile are only written
  /// when known, so a profile edit never clears them (the health profile is
  /// changed, and cleared, by its own sheet).
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
      if (allergies != null) "allergies": allergies,
      if (conditions != null) "conditions": conditions,
      if (bloodType != null) "bloodType": bloodType,
      if (emergencyContact != null) "emergencyContact": emergencyContact,
    };
  }
}
