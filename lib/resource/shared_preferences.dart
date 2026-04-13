import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static  SharedPreferences? prefs;

  static Future<bool> init() async {
    prefs = await SharedPreferences.getInstance();
    return prefs != null;
  }
}
