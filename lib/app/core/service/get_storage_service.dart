import 'package:baby_vax/app/core/imports/import_library.dart';
import 'package:baby_vax/app/core/values/storage_key.dart';

class GetStorageService extends GetxService {
  GetStorageService([GetStorage? box]) : _box = box ?? GetStorage();

  final GetStorage _box;

  Future<void> write(String key, dynamic value) => _box.write(key, value);

  dynamic read(String key) => _box.read(key);

  void remove(String key) => _box.remove(key);

  /// Erases everything, device preferences included.
  void clear() => _box.erase();

  /// Erases everything that belongs to the signed-in user — uid, login flag,
  /// child name — and keeps [StorageKey.devicePreferences]. Used on logout
  /// and account deletion.
  Future<void> clearUserData() async {
    final Map<String, dynamic> kept = <String, dynamic>{
      for (final String key in StorageKey.devicePreferences)
        if (_box.hasData(key)) key: _box.read(key),
    };
    await _box.erase();
    for (final MapEntry<String, dynamic> e in kept.entries) {
      await _box.write(e.key, e.value);
    }
  }
}
