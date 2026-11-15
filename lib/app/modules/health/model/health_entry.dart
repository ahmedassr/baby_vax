import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/health/health_guidance.dart';

/// What a Health log entry is about.
enum HealthEntryKind {
  temperature,
  symptoms,
  medicine,
  note;

  static HealthEntryKind? fromName(Object? v) {
    for (final HealthEntryKind k in values) {
      if (k.name == v) return k;
    }
    return null;
  }
}

/// One dated entry in `users/{uid}/health_log/{id}`: a temperature, a set
/// of signs, a medicine given, or a note. [doseId] links it to a vaccine
/// dose when it was logged from the after-vaccination card.
class HealthEntry {
  const HealthEntry({
    this.id,
    required this.kind,
    required this.at,
    this.tempC,
    this.method,
    this.symptoms = const <HealthSymptom>[],
    this.medicine,
    this.amount,
    this.note,
    this.doseId,
  });

  final String? id;
  final HealthEntryKind kind;

  /// When it happened, local wall-clock.
  final DateTime at;
  final double? tempC;
  final TemperatureMethod? method;
  final List<HealthSymptom> symptoms;

  /// The medicine's name and the amount, as the parent writes them. The
  /// app gives no dosing advice.
  final String? medicine;
  final String? amount;
  final String? note;
  final String? doseId;

  static const int maxMedicine = 80;
  static const int maxAmount = 40;
  static const int maxNote = 500;

  /// The range a typed reading must fall in (the rules' bounds): catches a
  /// reading typed in °F or with a slipped digit.
  static const double minTempC = 32;
  static const double maxTempC = 44;

  /// Whether it has what its kind needs (as the rules require).
  bool get isComplete => switch (kind) {
        HealthEntryKind.temperature =>
          tempC != null && tempC! >= minTempC && tempC! <= maxTempC,
        HealthEntryKind.symptoms => symptoms.isNotEmpty,
        HealthEntryKind.medicine => (medicine ?? '').trim().isNotEmpty,
        HealthEntryKind.note => (note ?? '').trim().isNotEmpty,
      };

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory HealthEntry.fromJson(String? id, Map<String, dynamic> json) {
    final Object? at = json['at'];
    final Object? temp = json['tempC'];
    final Object? method = json['method'];
    final Object? symptoms = json['symptoms'];
    return HealthEntry(
      id: id,
      kind: HealthEntryKind.fromName(json['kind']) ?? HealthEntryKind.note,
      at: at is Timestamp
          ? at.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
      tempC: temp is num ? temp.toDouble() : null,
      method: TemperatureMethod.values
          .where((TemperatureMethod m) => m.name == method)
          .firstOrNull,
      symptoms: symptoms is List
          ? symptoms
              .map((Object? s) => HealthSymptom.fromName(s as String?))
              .whereType<HealthSymptom>()
              .toList()
          : const <HealthSymptom>[],
      medicine: _text(json['medicine']),
      amount: _text(json['amount']),
      note: _text(json['note']),
      doseId: _text(json['doseId']),
    );
  }

  factory HealthEntry.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    return HealthEntry.fromJson(
        doc.id, raw is Map<String, dynamic> ? raw : <String, dynamic>{});
  }

  /// The document, with only the fields that are set.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'kind': kind.name,
        'at': Timestamp.fromDate(at),
        if (tempC != null) 'tempC': tempC,
        if (method != null) 'method': method!.name,
        if (symptoms.isNotEmpty)
          'symptoms': <String>[for (final HealthSymptom s in symptoms) s.name],
        if (_text(medicine) != null) 'medicine': _text(medicine),
        if (_text(amount) != null) 'amount': _text(amount),
        if (_text(note) != null) 'note': _text(note),
        if (doseId != null) 'doseId': doseId,
      };

  HealthEntry copyWith({String? id}) => HealthEntry(
        id: id ?? this.id,
        kind: kind,
        at: at,
        tempC: tempC,
        method: method,
        symptoms: symptoms,
        medicine: medicine,
        amount: amount,
        note: note,
        doseId: doseId,
      );

  /// Newest first; ties keep a stable order by id.
  static List<HealthEntry> newestFirst(Iterable<HealthEntry> entries) =>
      entries.toList()
        ..sort((HealthEntry a, HealthEntry b) {
          final int c = b.at.compareTo(a.at);
          return c != 0 ? c : (a.id ?? '').compareTo(b.id ?? '');
        });
}
