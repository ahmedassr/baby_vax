import 'package:baby_vax/app/config/constant/app_path.dart';
import 'package:baby_vax/app/core/imports/import_manger.dart';

/// Rules for a dose's state.
///
/// Stored states are exactly the three the Firestore rules allow: Pending,
/// Completed and Skipped. Only the user changes them; the app never moves a
/// dose between states on its own.
///
/// "Overdue" is not a state. It is how a Pending dose whose day has passed is
/// displayed, and it is never written to Firestore.
///
/// Comparisons are by calendar day: a dose is due on a day, not at an instant,
/// so a dose due today is neither overdue nor in the future.
class VaccineStatePolicy {
  const VaccineStatePolicy._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static MedicalDateStateEnum stateOf(MedicalDatesModel dose) =>
      MedicalDateStateEnum.fromLabel(dose.state);

  static bool isPending(MedicalDatesModel dose) =>
      stateOf(dose) == MedicalDateStateEnum.pending;

  /// Pending and due before today.
  static bool isOverdue(MedicalDatesModel dose, DateTime now) =>
      isPending(dose) && _day(dose.date).isBefore(_day(now));

  /// Due after today.
  static bool isInFuture(MedicalDatesModel dose, DateTime now) =>
      _day(dose.date).isAfter(_day(now));

  static bool canMarkCompleted(MedicalDatesModel dose) => isPending(dose);

  static bool canMarkSkipped(MedicalDatesModel dose) => isPending(dose);

  /// Completed or Skipped can go back to Pending.
  static bool canUndo(MedicalDatesModel dose) => !isPending(dose);

  /// Marking a future dose as given is allowed but asks for confirmation, since
  /// it is more likely a mis-tap than a dose given early.
  static bool completionNeedsConfirmation(
          MedicalDatesModel dose, DateTime now) =>
      canMarkCompleted(dose) && isInFuture(dose, now);

  /// What the UI shows for [dose] on [now]'s day: the stored state, except
  /// that a pending dose whose day has passed shows as overdue.
  static DoseDisplayStatus displayStatus(MedicalDatesModel dose, DateTime now) {
    switch (stateOf(dose)) {
      case MedicalDateStateEnum.completed:
        return DoseDisplayStatus.completed;
      case MedicalDateStateEnum.skipped:
        return DoseDisplayStatus.skipped;
      case MedicalDateStateEnum.pending:
        return isOverdue(dose, now)
            ? DoseDisplayStatus.overdue
            : DoseDisplayStatus.pending;
    }
  }
}

/// Thrown when an action is not allowed from the dose's current state.
class InvalidStateTransition implements Exception {
  InvalidStateTransition(this.from, this.to);

  final MedicalDateStateEnum from;
  final MedicalDateStateEnum to;

  @override
  String toString() =>
      'InvalidStateTransition: ${from.label} -> ${to.label} is not allowed';
}

/// Persists a dose's state and its record.
abstract class DoseStateWriter {
  /// Writes `state`. With [record], also writes its non-empty fields; with
  /// [clearRecord], deletes every record field (undoing a given dose: it
  /// was not given after all).
  Future<WriteOutcome> writeState(
    String doseId,
    MedicalDateStateEnum state, {
    DoseRecord? record,
    bool clearRecord = false,
  });

  /// Replaces the record of a dose that stays given (editing the clinic or
  /// batch later). Fields left blank are deleted.
  Future<WriteOutcome> writeRecord(String doseId, DoseRecord record);
}

/// The dose after a state change, and whether the change reached the
/// server or is waiting to sync.
class StateChange {
  const StateChange(this.dose, this.outcome);

  final MedicalDatesModel dose;
  final WriteOutcome outcome;
}

/// The reminders for one dose.
abstract class DoseReminders {
  Future<void> cancel(String doseId);

  /// Reschedules both reminders. Past dates and dates beyond the scheduling
  /// horizon are skipped by the implementation.
  Future<void> schedule(MedicalDatesModel dose);
}

/// Applies a user's state change: writes the state, then brings the dose's
/// reminders in line with it.
///
///   Completed / Skipped -> reminders cancelled
///   undo to Pending     -> reminders rescheduled
class VaccineStateService {
  VaccineStateService({
    required DoseStateWriter writer,
    required DoseReminders reminders,
  })  : _writer = writer,
        _reminders = reminders;

  final DoseStateWriter _writer;
  final DoseReminders _reminders;

  /// Marks [dose] as given, with an optional [record] of when and where.
  Future<StateChange> markCompleted(MedicalDatesModel dose,
          {DoseRecord record = const DoseRecord()}) =>
      _apply(dose, MedicalDateStateEnum.completed,
          allowed: VaccineStatePolicy.canMarkCompleted(dose), record: record);

  /// Updates the record of a dose that is already given.
  Future<StateChange> updateRecord(
      MedicalDatesModel dose, DoseRecord record) async {
    final String? id = dose.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError.value(dose.id, 'dose.id', 'must be a saved record');
    }
    if (VaccineStatePolicy.stateOf(dose) != MedicalDateStateEnum.completed) {
      throw InvalidStateTransition(
          VaccineStatePolicy.stateOf(dose), MedicalDateStateEnum.completed);
    }
    final DoseRecord clean = record.normalised();
    final WriteOutcome outcome = await _writer.writeRecord(id, clean);
    return StateChange(dose.copyWith(record: clean), outcome);
  }

  Future<StateChange> markSkipped(MedicalDatesModel dose) =>
      _apply(dose, MedicalDateStateEnum.skipped,
          allowed: VaccineStatePolicy.canMarkSkipped(dose));

  Future<StateChange> undo(MedicalDatesModel dose) =>
      _apply(dose, MedicalDateStateEnum.pending,
          allowed: VaccineStatePolicy.canUndo(dose));

  Future<StateChange> _apply(
    MedicalDatesModel dose,
    MedicalDateStateEnum to, {
    required bool allowed,
    DoseRecord record = const DoseRecord(),
  }) async {
    final String? id = dose.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError.value(dose.id, 'dose.id', 'must be a saved record');
    }
    if (!allowed) {
      throw InvalidStateTransition(VaccineStatePolicy.stateOf(dose), to);
    }

    // A dose that goes back to pending was not given after all, so whatever
    // was recorded about giving it is removed with it.
    final bool clearRecord = to == MedicalDateStateEnum.pending;
    final DoseRecord written = to == MedicalDateStateEnum.completed
        ? record.normalised()
        : const DoseRecord();

    // Returns once the change is stored on the device; offline it does not
    // wait for the server (see awaitAck).
    final WriteOutcome outcome = await _writer.writeState(
      id,
      to,
      record: written.isEmpty ? null : written,
      clearRecord: clearRecord,
    );

    final MedicalDatesModel updated = dose.copyWith(
      state: to.label,
      record: clearRecord ? const DoseRecord() : written,
    );
    if (to == MedicalDateStateEnum.pending) {
      await _reminders.schedule(updated);
    } else {
      await _reminders.cancel(id);
    }
    return StateChange(updated, outcome);
  }
}

/// [DoseStateWriter] backed by the signed-in user's schedule in Firestore.
class FirestoreDoseStateWriter implements DoseStateWriter {
  String _path(String doseId) =>
      '${AppPath.userMedicalDates(SessionManager.signedInUid ?? '')}/$doseId';

  /// Every record field set to "delete".
  static Map<String, dynamic> get _deleteRecord => <String, dynamic>{
        for (final String f in DoseRecord.fields) f: FieldValue.delete(),
      };

  @override
  Future<WriteOutcome> writeState(
    String doseId,
    MedicalDateStateEnum state, {
    DoseRecord? record,
    bool clearRecord = false,
  }) {
    return AppConstant.fireStoreHelper1.updateData(
      path: _path(doseId),
      data: <String, dynamic>{
        'state': state.label,
        if (clearRecord) ..._deleteRecord,
        if (record != null) ...record.toMap(),
      },
    );
  }

  @override
  Future<WriteOutcome> writeRecord(String doseId, DoseRecord record) {
    return AppConstant.fireStoreHelper1.updateData(
      path: _path(doseId),
      // Delete first, then set what is filled in: a field cleared in the
      // form is removed rather than left behind.
      data: <String, dynamic>{..._deleteRecord, ...record.toMap()},
    );
  }
}

/// [DoseReminders] backed by [NotificationCoordinator].
class CoordinatorDoseReminders implements DoseReminders {
  NotificationCoordinator get _coordinator =>
      Get.find<NotificationCoordinator>();

  @override
  Future<void> cancel(String doseId) => _coordinator.cancelVaccine(doseId);

  @override
  Future<void> schedule(MedicalDatesModel dose) {
    return _coordinator.scheduleVaccine(
      vaccineId: dose.id!,
      userName: reminderChildName(
          AppConstant.getStorage.read(StorageKey.userNameKey)),
      vaccineName: dose.displayName,
      date: dose.date,
    );
  }
}
