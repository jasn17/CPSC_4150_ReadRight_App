// FILE: lib/models/settings_model.dart
// PURPOSE: App-wide settings (assessor provider, score threshold, retain audio, retention days).
// TOOLS: ChangeNotifier.
// RELATIONSHIPS: Controlled by settings_screen.dart; influences which service implementations are used at runtime.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/themes/theme_registry.dart';
import '/themes/theme_definition.dart';




class SettingsModel extends ChangeNotifier {
  String _assessor = 'local';
  int _threshold = 80;
  bool _retainAudio = false;

  String get assessor => _assessor;
  int get threshold => _threshold;
  bool get retainAudio => _retainAudio;

  set assessor(String v) { _assessor = v; notifyListeners(); }
  set threshold(int v) { _threshold = v; notifyListeners(); }
  set retainAudio(bool v) { _retainAudio = v; notifyListeners(); }


  // ----------------- persistence -----------------

  Future<void> _loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('threshold');
    if (stored != null) {
      _threshold = stored;
      notifyListeners();
      }
    }

    Future<void> _saveThreshold(int v) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('threshold', v);
    }


  // ------------------ theme logic ------------------
  static const _themeModeKey = 'themeMode';
  static const _themeIdKey = 'themeId';

  // Current theme mode (system / light / dark)
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode v) {
    _themeMode = v;
    _saveThemeMode(v);
    notifyListeners();
  }

  // Current theme ID (refers to AppThemeDefinition.id)
  String _themeId = availableThemes.first.id;
  String get themeId => _themeId;
  set themeId(String id) {
    _themeId = id;
    _saveThemeId(id);
    notifyListeners();
  }

  // Convenience getter for current theme object
  AppThemeDefinition get currentTheme =>
      availableThemes.firstWhere((t) => t.id == _themeId);

  // List of available themes
  List<AppThemeDefinition> get themes => availableThemes;

  // ------------------ constructor ------------------
  SettingsModel() {
    _loadThemeMode();
    _loadThemeId();
  }

  // ------------------ persistence ------------------
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_themeModeKey);
    if (stored != null) {
      _themeMode = ThemeMode.values[stored];
      notifyListeners();
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> _loadThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeIdKey);
    if (stored != null && themes.any((t) => t.id == stored)) {
      _themeId = stored;
      notifyListeners();
    }
  }

  Future<void> _saveThemeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, id);
  }
}



