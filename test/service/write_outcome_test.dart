import 'dart:async';

import 'package:baby_vax/app/core/service/write_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Duration grace = Duration(milliseconds: 50);

  test('an acknowledged write reports synced', () async {
    expect(await awaitAck(Future<void>.value(), grace: grace),
        WriteOutcome.synced);
  });

  test('a write with no server ack does not block: it reports pendingSync',
      () async {
    // Offline, Firestore never completes the write's Future.
    final Completer<void> neverAcked = Completer<void>();
    final Stopwatch sw = Stopwatch()..start();
    final WriteOutcome outcome =
        await awaitAck(neverAcked.future, grace: grace);
    sw.stop();
    expect(outcome, WriteOutcome.pendingSync);
    expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
  });

  test('an error inside the grace period reaches the caller', () async {
    await expectLater(
        awaitAck(Future<void>.error(StateError('permission-denied')),
            grace: grace),
        throwsStateError);
  });

  test('an error after the grace period goes to onLateError', () async {
    final Completer<void> ack = Completer<void>();
    Object? late;
    final WriteOutcome outcome = await awaitAck(ack.future,
        grace: grace, onLateError: (e, _) => late = e);
    expect(outcome, WriteOutcome.pendingSync);

    ack.completeError(StateError('rejected on reconnect'));
    await Future<void>.delayed(Duration.zero);
    expect(late, isA<StateError>());
  });

  test('a late ack after pendingSync is harmless', () async {
    final Completer<void> ack = Completer<void>();
    final WriteOutcome outcome = await awaitAck(ack.future, grace: grace);
    expect(outcome, WriteOutcome.pendingSync);
    ack.complete();
    await Future<void>.delayed(Duration.zero);
  });
}
