// FILE: lib/models/practice_model.dart
// PURPOSE: Tracks current target, mic state, and last PracticeResult.
// TOOLS: ChangeNotifier.
// RELATIONSHIPS: Written by practice_screen.dart; read by feedback_screen.dart; later orchestrates AudioService -> STTService -> ScoringService and persists via attempts_repository.dart.

import 'package:flutter/foundation.dart';
import 'word_list_model.dart';

class PracticeResult {
  final String transcript;
  final int score; // 0-100
  final bool correct;
  PracticeResult({required this.transcript, required this.score, required this.correct});
}

class PracticeModel extends ChangeNotifier {
  WordItem? _target;
  PracticeResult? _last;

  WordItem? get target => _target;
  PracticeResult? get lastResult => _last;

  void setTarget(WordItem item) {
    _target = item;
    _last = null;
    notifyListeners();
  }

  // For skeleton screenshots: produce a deterministic fake result.
  void fakeAssess() {
    if (_target == null) return;
    final t = _target!;
    _last = PracticeResult(transcript: t.word, score: 92, correct: true);
    notifyListeners();
  }

  void reset() {
    _last = null;
    notifyListeners();
  }
}
