import 'dart:async';

/// What the user should be told after a save.
enum WriteOutcome {
  /// The server acknowledged the write.
  synced,

  /// Saved on the device. Firestore will send it when the connection is
  /// back. Offline, Firestore applies a write to its local cache immediately
  /// but only completes the write's Future when the server acknowledges it,
  /// which can take until the next time the phone is online.
  pendingSync,
}

/// Waits for a write's server acknowledgement for at most [grace].
///
/// Returns [WriteOutcome.synced] if [ack] completes in time and
/// [WriteOutcome.pendingSync] otherwise, so the UI never waits on the
/// network. An error inside [grace] is rethrown (for example a rules
/// denial while online). An error after [grace] can no longer reach the
/// caller and goes to [onLateError].
///
/// A timeout is used instead of a connectivity check because "has a
/// network" is not "can reach Firestore": behind a captive portal the phone
/// reports wifi and every request still hangs.
Future<WriteOutcome> awaitAck(
  Future<void> ack, {
  Duration grace = const Duration(seconds: 2),
  void Function(Object error, StackTrace stack)? onLateError,
}) async {
  final Completer<WriteOutcome> result = Completer<WriteOutcome>();
  final Timer timer = Timer(grace, () {
    if (!result.isCompleted) result.complete(WriteOutcome.pendingSync);
  });

  ack.then((_) {
    timer.cancel();
    if (!result.isCompleted) result.complete(WriteOutcome.synced);
  }, onError: (Object e, StackTrace s) {
    timer.cancel();
    if (!result.isCompleted) {
      result.completeError(e, s);
    } else {
      onLateError?.call(e, s);
    }
  });

  return result.future;
}
