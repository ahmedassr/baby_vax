import 'package:baby_vax/app/core/imports/import_library.dart';

/// What was recorded when a dose was given: when, where, which batch, and a
/// note. Every field is optional; a dose marked as given with nothing filled
/// in has no record at all, exactly as in v1.0.
class DoseRecord {
  const DoseRecord({this.givenDate, this.clinic, this.lot, this.note});

  /// The day the dose was actually given (may differ from the scheduled
  /// date).
  final DateTime? givenDate;

  /// Clinic or place.
  final String? clinic;

  /// Batch / lot number from the vial or the clinic card.
  final String? lot;

  /// A short free-text note.
  final String? note;

  /// Lengths the Firestore rules accept.
  static const int maxClinic = 120;
  static const int maxLot = 60;
  static const int maxNote = 500;

  /// The Firestore field names, which must stay in step with
  /// `isValidMedicalDate` in firestore.rules.
  static const List<String> fields = <String>[
    'givenDate',
    'clinic',
    'lot',
    'note',
  ];

  bool get isEmpty =>
      givenDate == null &&
      (clinic ?? '').trim().isEmpty &&
      (lot ?? '').trim().isEmpty &&
      (note ?? '').trim().isEmpty;

  static String? _clean(String? v) {
    final String t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// Trimmed, with blank strings dropped.
  DoseRecord normalised() => DoseRecord(
        givenDate: givenDate == null
            ? null
            : DateTime(givenDate!.year, givenDate!.month, givenDate!.day),
        clinic: _clean(clinic),
        lot: _clean(lot),
        note: _clean(note),
      );

  /// The fields to write: only those that have a value.
  Map<String, dynamic> toMap() {
    final DoseRecord r = normalised();
    return <String, dynamic>{
      if (r.givenDate != null) 'givenDate': Timestamp.fromDate(r.givenDate!),
      if (r.clinic != null) 'clinic': r.clinic,
      if (r.lot != null) 'lot': r.lot,
      if (r.note != null) 'note': r.note,
    };
  }
}

class MedicalDatesModel {
  MedicalDatesModel({
    required this.name,
    required this.description,
    required this.date,
    required this.state,
    this.id,
    this.code,
    this.record = const DoseRecord(),
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

  /// What was recorded when the dose was given (v1.1). Empty for v1.0
  /// documents and for doses not given yet.
  final DoseRecord record;

  MedicalDatesModel copyWith({
    String? name,
    String? description,
    DateTime? date,
    String? state,
    String? id,
    String? code,
    DoseRecord? record,
  }) {
    return MedicalDatesModel(
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      state: state ?? this.state,
      id: id ?? this.id,
      code: code ?? this.code,
      record: record ?? this.record,
    );
  }

  factory MedicalDatesModel.fromJson(Map<String, dynamic>? json) =>
      MedicalDatesModel._fromMap(
          json ?? const <String, dynamic>{}, json?['id']);

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
    final Object? given = data['givenDate'];
    return MedicalDatesModel(
      id: id,
      code: data['code'] as String?,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      date: _parseDate(data['date']),
      state: (data['state'] as String?) ?? '',
      record: DoseRecord(
        givenDate: given == null ? null : _parseDate(given),
        clinic: data['clinic'] is String ? data['clinic'] as String : null,
        lot: data['lot'] is String ? data['lot'] as String : null,
        note: data['note'] is String ? data['note'] as String : null,
      ),
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

  /// The whole document, record fields included. Used for full writes
  /// (sign-up, moving the schedule to a corrected birth date), so it must
  /// carry everything or a full write would drop the record.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'state': state,
      if (code != null) 'code': code,
      ...record.toMap(),
    };
  }
}
