/// Deterministic mapping from a reminder's string key to an Android/iOS
/// notification id.
///
/// Why not `String.hashCode`: Dart makes no promise that `String.hashCode` is
/// stable across VM versions or platforms, and its value can exceed the signed
/// 32-bit range that Android notification ids must fit in. An id that shifts
/// between app versions means `cancel()` silently misses the notification it
/// was meant to replace, which is exactly how duplicate reminders appear.
///
/// FNV-1a (32-bit) is a fixed, specified algorithm, so the same key always
/// produces the same id — on every platform, on every build. The result is
/// masked to 31 bits so it is always a non-negative `int`.
library;

int stableNotificationId(String key) {
  const int fnvOffsetBasis = 0x811c9dc5;
  const int fnvPrime = 0x01000193;
  const int mask32 = 0xffffffff;

  int hash = fnvOffsetBasis;
  for (final int byte in key.codeUnits) {
    hash = (hash ^ (byte & 0xff)) & mask32;
    hash = (hash * fnvPrime) & mask32;
  }
  // Drop the sign bit: Android requires the id to fit in a signed 32-bit int.
  return hash & 0x7fffffff;
}
