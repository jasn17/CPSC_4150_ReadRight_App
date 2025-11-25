// FILE: lib/models/progress_model.dart
// PURPOSE: Stores attempt summaries and computes aggregate metrics (avg).
// TOOLS: ChangeNotifier, LocalDbService for real data.
// RELATIONSHIPS: Read by progress_screen.dart; hydrated from local database.

import 'package:flutter/foundation.dart';
import '../services/local_db_service.dart';
import '../models/practice_attempt.dart';

class AttemptSummary {
  final String word;
  final int score;
  final DateTime at;
  final bool correct;
  
  AttemptSummary(this.word, this.score, this.at, this.correct);
  
  factory AttemptSummary.fromAttempt(PracticeAttempt attempt) {
    return AttemptSummary(
      attempt.targetWord,
      attempt.score,
      attempt.timestamp,
      attempt.correct,
    );
  }
}

class ProgressModel extends ChangeNotifier {
  final LocalDbService _localDb = LocalDbService.instance;
  List<AttemptSummary> _attempts = [];
  String? _currentUserId;
  bool _isLoading = false;

  List<AttemptSummary> get attempts => List.unmodifiable(_attempts);
  bool get isLoading => _isLoading;
  
  int get average {
    if (_attempts.isEmpty) return 0;
    final sum = _attempts.map((a) => a.score).reduce((a, b) => a + b);
    return (sum / _attempts.length).round();
  }

  /// Load attempts for a specific user
  Future<void> loadAttemptsForUser(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      final dbAttempts = await _localDb.getAttemptsForUser(userId);
      _attempts = dbAttempts
          .map((attempt) => AttemptSummary.fromAttempt(attempt))
          .toList();
    } catch (e) {
      debugPrint('ProgressModel: Error loading attempts: $e');
      _attempts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load attempts for current user by date range
  Future<void> loadAttemptsByDateRange(DateTime startDate, DateTime endDate) async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final dbAttempts = await _localDb.getAttemptsByDateRange(
        _currentUserId!,
        startDate,
        endDate,
      );
      _attempts = dbAttempts
          .map((attempt) => AttemptSummary.fromAttempt(attempt))
          .toList();
    } catch (e) {
      debugPrint('ProgressModel: Error loading attempts by date range: $e');
      _attempts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh attempts (call after new practice sessions)
  Future<void> refresh() async {
    if (_currentUserId != null) {
      await loadAttemptsForUser(_currentUserId!);
    }
  }

  /// Add a new attempt (called when practice completes)
  void add(String word, int score, bool correct) {
    _attempts.insert(
      0,
      AttemptSummary(word, score, DateTime.now(), correct),
    );
    notifyListeners();
  }

  /// Get most missed words (words with lowest average scores)
  /// Returns a list of (word, averageScore, attemptCount) sorted by worst performance
  List<({String word, double avgScore, int attempts})> getMostMissedWords({int limit = 10}) {
    if (_attempts.isEmpty) return [];

    // Group attempts by word
    final Map<String, List<int>> wordScores = {};
    
    for (final attempt in _attempts) {
      wordScores.putIfAbsent(attempt.word, () => []);
      wordScores[attempt.word]!.add(attempt.score);
    }

    // Calculate average score for each word
    final wordStats = wordScores.entries.map((entry) {
      final word = entry.key;
      final scores = entry.value;
      final avgScore = scores.reduce((a, b) => a + b) / scores.length;
      
      return (
        word: word,
        avgScore: avgScore,
        attempts: scores.length,
      );
    }).toList();

    // Sort by average score (lowest first) - these are the "most missed"
    wordStats.sort((a, b) => a.avgScore.compareTo(b.avgScore));

    // Return top N worst performing words
    return wordStats.take(limit).toList();
  }

  /// Get words that need more practice (incorrect > 50% of the time)
  List<({String word, double successRate, int attempts})> getWordsNeedingPractice() {
    if (_attempts.isEmpty) return [];

    // Group attempts by word
    final Map<String, List<bool>> wordResults = {};
    
    for (final attempt in _attempts) {
      wordResults.putIfAbsent(attempt.word, () => []);
      wordResults[attempt.word]!.add(attempt.correct);
    }

    // Calculate success rate for each word
    final wordStats = wordResults.entries.map((entry) {
      final word = entry.key;
      final results = entry.value;
      final correctCount = results.where((correct) => correct).length;
      final successRate = correctCount / results.length;
      
      return (
        word: word,
        successRate: successRate,
        attempts: results.length,
      );
    }).toList();

    // Filter words with success rate < 50%
    final needsPractice = wordStats.where((stat) => stat.successRate < 0.5).toList();

    // Sort by success rate (lowest first)
    needsPractice.sort((a, b) => a.successRate.compareTo(b.successRate));

    return needsPractice;
  }

  /// Get improvement trend: compare recent performance to earlier performance
  /// Returns positive number if improving, negative if declining
  double getImprovementTrend({int recentCount = 10}) {
    if (_attempts.length < recentCount * 2) return 0.0;

    // Split attempts into recent and older
    final recentAttempts = _attempts.take(recentCount).toList();
    final olderAttempts = _attempts.skip(recentCount).take(recentCount).toList();

    // Calculate average scores
    final recentAvg = recentAttempts.map((a) => a.score).reduce((a, b) => a + b) / recentCount;
    final olderAvg = olderAttempts.map((a) => a.score).reduce((a, b) => a + b) / recentCount;

    // Return difference (positive = improvement, negative = decline)
    return recentAvg - olderAvg;
  }
}