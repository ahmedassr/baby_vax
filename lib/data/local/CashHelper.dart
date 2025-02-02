import 'package:shared_preferences/shared_preferences.dart';

class CashHelper {
  static SharedPreferences? sharedPreferences;

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool?> putValue(
      {required String key, required dynamic value}) async {
    if (sharedPreferences == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    } else {
      if (value is int) return await sharedPreferences?.setInt(key, value);
      if (value is String) return await sharedPreferences?.setString(key, value);
      if (value is bool) return await sharedPreferences?.setBool(key, value);
      return await sharedPreferences?.setDouble(key, value);
    }
  }

  static String? getString({required String key}) {
    return sharedPreferences?.getString(key);
  }

  static bool? getBool({required String key}) {
    return sharedPreferences?.getBool(key);
  }
}
