import 'package:baby_vax/app/core/imports/import_library.dart';

class MedicalDatesModel {
  MedicalDatesModel({
    required this.name,
    required this.description,
    required this.date,
    required this.state,
    this.id,
    this.code,
  });

  /// Firestore document id. Null for a record not yet written.
  final String? id;

  /// Stable schedule code (see [MedicalDatesGenerator]). Null for records
  /// created before codes existed; display falls back to [name].
  final String? code;

  final String name;
  final String description;
  final DateTime date;
  final String state;

  MedicalDatesModel copyWith({
    String? name,
    String? description,
    DateTime? date,
    String? state,
    String? id,
    String? code,
  }) {
    return MedicalDatesModel(
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      state: state ?? this.state,
      id: id ?? this.id,
      code: code ?? this.code,
    );
  }

  factory MedicalDatesModel.fromJson(Map<String, dynamic>? json) =>
      MedicalDatesModel._fromMap(json ?? const <String, dynamic>{}, json?['id']);

  factory MedicalDatesModel.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    final Map<String, dynamic> data =
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return MedicalDatesModel._fromMap(data, doc.id);
  }

  /// Tolerant of partial documents.
  ///
  /// The previous version read `data["name"]` and `data["description"]`
  /// straight into non-nullable fields and assumed `date` was always a
  /// `Timestamp`, so a document written by an older build, or one missing a
  /// field, threw while parsing and took out the whole schedule screen.
  factory MedicalDatesModel._fromMap(Map<String, dynamic> data, String? id) {
    return MedicalDatesModel(
      id: id,
      code: data['code'] as String?,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      date: _parseDate(data['date']),
      state: (data['state'] as String?) ?? '',
    );
  }

  /// Accepts a Firestore [Timestamp], a [DateTime], or an ISO-8601 string.
  ///
  /// Falls back to the epoch rather than throwing: a single malformed date
  /// should leave that one row looking wrong, not break the list.
  static DateTime _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'state': state,
      if (code != null) 'code': code,
    };
  }
}
