// FILE: lib/models/settings_model.dart
// PURPOSE: App-wide settings (assessor provider, score threshold, retain audio, retention days).
// TOOLS: ChangeNotifier.
// RELATIONSHIPS: Controlled by settings_screen.dart; influences which service implementations are used at runtime.

import 'package:flutter/foundation.dart';

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
}
