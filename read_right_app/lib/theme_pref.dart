import 'package:shared_preferences/shared_preferences.dart';


class ThemePrefs {
  static const String _kDarkMode = 'pref_dark_mode';


  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDarkMode) ?? false; // default: light mode
  }


  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }
}