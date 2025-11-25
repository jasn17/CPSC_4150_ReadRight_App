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
}