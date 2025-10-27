import 'package:shared_preferences/shared_preferences.dart';

class ThemePrefs {
  static const _kDark = 'pref_dark_mode';

  Future<bool> getDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDark) ?? false;
  }

  Future<void> setDarkMode(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, v);
  }
}
