import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/service/growth/motor_milestones.dart';

/// What the parent recorded for one milestone,
/// `users/{uid}/milestones/{milestoneId}`.
///
/// [achievedAt] is the day the baby did it. A record without it holds only
/// a note for the doctor visit (the milestone is not achieved yet).
class MilestoneRecord {
  const MilestoneRecord({required this.milestone, this.achievedAt, this.note});

  final MotorMilestone milestone;
  final DateTime? achievedAt;
  final String? note;

  static const int maxNote = 300;

  bool get achieved => achievedAt != null;

  MilestoneRecord copyWith({DateTime? achievedAt, String? note}) =>
      MilestoneRecord(
        milestone: milestone,
        achievedAt: achievedAt ?? this.achievedAt,
        note: note ?? this.note,
      );

  /// Null for a document whose id is not one of the six milestones.
  static MilestoneRecord? fromMap(String id, Map<String, dynamic> data) {
    final MotorMilestone? m = MotorMilestone.fromId(id);
    if (m == null) return null;
    final Object? at = data['achievedAt'];
    final Object? note = data['note'];
    return MilestoneRecord(
      milestone: m,
      achievedAt: at is Timestamp
          ? at.toDate()
          : at is DateTime
              ? at
              : null,
      note: note is String && note.trim().isNotEmpty ? note : null,
    );
  }

  static MilestoneRecord? fromDocument(DocumentSnapshot doc) {
    final Object? raw = doc.data();
    return fromMap(
        doc.id, raw is Map<String, dynamic> ? raw : const <String, dynamic>{});
  }

  /// The document: the day only (midnight), and the note when there is one.
  Map<String, dynamic> toMap() => <String, dynamic>{
        if (achievedAt != null)
          'achievedAt': Timestamp.fromDate(
              DateTime(achievedAt!.year, achievedAt!.month, achievedAt!.day)),
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  /// Whether there is anything to store.
  bool get isEmpty => achievedAt == null && (note ?? '').trim().isEmpty;
}
