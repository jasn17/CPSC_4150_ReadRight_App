// FILE: lib/models/progress_model.dart
// PURPOSE: Stores attempt summaries and computes aggregate metrics (avg).
// TOOLS: ChangeNotifier.
// RELATIONSHIPS: Read by progress_screen.dart; later hydrated by data/attempts_repository.dart.

import 'package:flutter/foundation.dart';

class AttemptSummary {
  final String word;
  final int score;
  final DateTime at;
  AttemptSummary(this.word, this.score, this.at);
}

class ProgressModel extends ChangeNotifier {
  final List<AttemptSummary> _attempts = [
    AttemptSummary('cat', 92, DateTime.now().subtract(const Duration(days: 1))),
    AttemptSummary('ship', 84, DateTime.now().subtract(const Duration(days: 2))),
    AttemptSummary('dog', 95, DateTime.now().subtract(const Duration(days: 3))),
  ];

  List<AttemptSummary> get attempts => List.unmodifiable(_attempts);
  int get average =>
      _attempts.isEmpty ? 0 : (_attempts.map((a) => a.score).reduce((a, b) => a + b) ~/ _attempts.length);

  void add(String word, int score) {
    _attempts.insert(0, AttemptSummary(word, score, DateTime.now()));
    notifyListeners();
  }
}
