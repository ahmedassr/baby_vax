import 'package:baby_vax/app/core/imports/import_library.dart';

/// The three things the growth tracker measures, with the Firestore field
/// each is stored in.
enum GrowthMetric {
  weight('weightKg'),
  height('heightCm'),
  head('headCm');

  const GrowthMetric(this.field);

  /// Field name in `users/{uid}/measurements/{id}`; must match
  /// `isValidMeasurement` in firestore.rules.
  final String field;

  /// Plausibility bounds, the same as the rules enforce. They catch typos,
  /// not unusual children: the app covers ages up to 18.
  ({double min, double max}) get bounds => switch (this) {
        GrowthMetric.weight => (min: 0.3, max: 150),
        GrowthMetric.height => (min: 20, max: 220),
        GrowthMetric.head => (min: 20, max: 70),
      };
}

/// One dated set of measurements, `users/{uid}/measurements/{id}`.
///
/// Any of the three values may be missing (a clinic visit where only the
/// weight was taken); at least one is always present.
class MeasurementModel {
  const MeasurementModel({
    this.id,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.headCm,
    this.note,
  });

  final String? id;

  /// The day it was measured.
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? headCm;
  final String? note;

  static const int maxNote = 500;

  double? valueOf(GrowthMetric m) => switch (m) {
        GrowthMetric.weight => weightKg,
        GrowthMetric.height => heightCm,
        GrowthMetric.head => headCm,
      };

  bool get isEmpty => weightKg == null && heightCm == null && headCm == null;

  MeasurementModel copyWith({String? id}) => MeasurementModel(
        id: id ?? this.id,
        date: date,
        weightKg: weightKg,
        heightCm: heightCm,
        headCm: headCm,
        note: note,
      );

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  factory MeasurementModel.fromMap(Map<String, dynamic> data, String? id) {
    final Object? d = data['date'];
    final Object? note = data['note'];
    return MeasurementModel(
      id: id,
      date: d is Timestamp
          ? d.toDate()
          : d is DateTime
              ? d
              : DateTime.fromMillisecondsSinceEpoch(0),
      weightKg: _num(data['weightKg']),
      heightCm: _num(data['heightCm']),
      headCm: _num(data['headCm']),
      note: note is String && note.trim().isNotEmpty ? note : null,
    );
  }

  factory MeasurementModel.fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    return MeasurementModel.fromMap(
        raw is Map<String, dynamic> ? raw : const <String, dynamic>{}, doc.id);
  }

  /// The document. Only the values that were measured are written.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        if (weightKg != null) 'weightKg': weightKg,
        if (heightCm != null) 'heightCm': heightCm,
        if (headCm != null) 'headCm': headCm,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  /// Newest first; ties by id so the order is stable.
  static List<MeasurementModel> newestFirst(Iterable<MeasurementModel> all) =>
      all.toList()
        ..sort((a, b) {
          final int c = b.date.compareTo(a.date);
          return c != 0 ? c : (b.id ?? '').compareTo(a.id ?? '');
        });

  /// For each metric, the most recent value measured, as the profile's
  /// v1.0 string fields want it ("4.2"). Null when never measured.
  static Map<GrowthMetric, String?> latestForProfile(
      Iterable<MeasurementModel> all) {
    final List<MeasurementModel> sorted = newestFirst(all);
    String? fmt(double? v) => v == null
        ? null
        : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');
    return <GrowthMetric, String?>{
      for (final GrowthMetric m in GrowthMetric.values)
        m: fmt(sorted
            .map((e) => e.valueOf(m))
            .firstWhere((v) => v != null, orElse: () => null)),
    };
  }
}
