/// Who to call about the child in an emergency: a name, a phone number and
/// how they are related to the child. Part of the v1.1 health profile,
/// stored as the map `users/{uid}.emergencyContact`.
class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation,
  });

  final String name;

  /// Digits only, with an optional leading "+" ([normalizePhone]).
  final String phone;

  /// One of [relations], or null when not given.
  final String? relation;

  static const int maxName = 60;
  static const int minDigits = 6;
  static const int maxDigits = 15;

  /// The relations the rules accept, in the order they are offered.
  static const List<String> relations = <String>[
    'mother', 'father', 'grandparent', 'sibling', 'relative', 'guardian', //
    'other',
  ];

  /// [raw] as stored: Arabic-Indic and Persian digits made Western, spaces,
  /// dashes, dots and brackets dropped, a leading "00" kept as "00" (the
  /// parent typed it). Null when it is not 6–15 digits with an optional
  /// leading "+".
  static String? normalizePhone(String raw) {
    const String arabic = '٠١٢٣٤٥٦٧٨٩';
    const String persian = '۰۱۲۳۴۵۶۷۸۹';
    final StringBuffer b = StringBuffer();
    for (final int c in raw.trim().runes) {
      final String ch = String.fromCharCode(c);
      final int a = arabic.indexOf(ch);
      final int p = persian.indexOf(ch);
      if (a >= 0) {
        b.write(a);
      } else if (p >= 0) {
        b.write(p);
      } else if (RegExp(r'[0-9+]').hasMatch(ch)) {
        b.write(ch);
      } else if (!RegExp('[\\s\\-.()\u200e\u200f]').hasMatch(ch)) {
        return null;
      }
    }
    final String s = b.toString();
    return RegExp('^\\+?[0-9]{$minDigits,$maxDigits}\$').hasMatch(s) ? s : null;
  }

  /// The contact stored at `emergencyContact`, or null when it is missing
  /// or not a valid contact.
  static EmergencyContact? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? name = json['name'];
    final Object? phone = json['phone'];
    if (name is! String || name.trim().isEmpty || phone is! String) {
      return null;
    }
    final String? p = normalizePhone(phone);
    if (p == null) return null;
    final Object? relation = json['relation'];
    return EmergencyContact(
      name: name.trim(),
      phone: p,
      relation:
          relation is String && relations.contains(relation) ? relation : null,
    );
  }

  Map<String, Object> toMap() => <String, Object>{
        'name': name,
        'phone': phone,
        if (relation != null) 'relation': relation!,
      };

  @override
  bool operator ==(Object other) =>
      other is EmergencyContact &&
      other.name == name &&
      other.phone == phone &&
      other.relation == relation;

  @override
  int get hashCode => Object.hash(name, phone, relation);
}
