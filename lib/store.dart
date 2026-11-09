import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence layer over SharedPreferences. One helper per type;
/// every key in the app lives here (settings, favourites, reading
/// progress, tasbeeh counters).
class Store {
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static String? s(String k) => _p.getString(k);
  static Future<void> setS(String k, String v) => _p.setString(k, v);
  static bool b(String k, {bool def = false}) => _p.getBool(k) ?? def;
  static Future<void> setB(String k, bool v) => _p.setBool(k, v);
  static int i(String k, {int def = 0}) => _p.getInt(k) ?? def;
  static Future<void> setI(String k, int v) => _p.setInt(k, v);
  static List<String> list(String k) => _p.getStringList(k) ?? [];
  static Future<void> setList(String k, List<String> v) =>
      _p.setStringList(k, v);
}
