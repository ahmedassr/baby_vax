import 'package:baby_vax/app/core/notification/domain/notification_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stableNotificationId', () {
    test('is deterministic for the same key', () {
      expect(stableNotificationId('vax_1-main'),
          stableNotificationId('vax_1-main'));
    });

    test('differs for the main and advance reminders of one vaccine', () {
      expect(stableNotificationId('vax_1-main'),
          isNot(stableNotificationId('vax_1-advance')));
    });

    test('differs across vaccines', () {
      expect(stableNotificationId('vax_1-main'),
          isNot(stableNotificationId('vax_2-main')));
    });

    test('always fits in a signed 32-bit int, as Android requires', () {
      // Firestore ids are 20 chars; include longer and unicode keys too.
      final List<String> keys = <String>[
        '',
        'a',
        'vax_1-main',
        'aB3kZ9qLmN2pXrT7wYvE-advance',
        'تطعيم-main',
        'x' * 512,
      ];
      for (final String key in keys) {
        final int id = stableNotificationId(key);
        expect(id, greaterThanOrEqualTo(0), reason: 'key=$key');
        expect(id, lessThanOrEqualTo(0x7fffffff), reason: 'key=$key');
      }
    });

    test('matches known FNV-1a 32-bit values, pinning the algorithm', () {
      // Reference vectors for FNV-1a/32. If these change, previously scheduled
      // reminders would stop being cancellable, so they are locked down.
      expect(stableNotificationId(''), 0x811c9dc5 & 0x7fffffff);
      expect(stableNotificationId('a'), 0xe40c292c & 0x7fffffff);
      expect(stableNotificationId('foobar'), 0xbf9cf968 & 0x7fffffff);
    });
  });
}
