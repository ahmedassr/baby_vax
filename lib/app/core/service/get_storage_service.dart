import 'package:baby_vax/app/core/imports/import_library.dart';

class GetStorageService extends GetxService {
  final GetStorage _box = GetStorage();

  void write(String key, dynamic value) => _box.write(key, value);

  dynamic read(String key) => _box.read(key);

  void remove(String key) => _box.remove(key);

  void clear() => _box.erase();
}
