import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



class FeedbackModel extends ChangeNotifier {
  final int maxItems;
  final List<FeedbackItem> _history = [];
  String? _userId;


  FeedbackModel({this.maxItems = 6});

  List<FeedbackItem> get history => List.unmodifiable(_history);

  void addFeedback(FeedbackItem item) {
    _history.insert(0, item);   // newest first

    if (_history.length > maxItems) {
      _history.removeLast();
    }

    notifyListeners();
  }

  FeedbackItem? getByIndex(int index) {
    if (index < 0 || index >= _history.length) return null;
    return _history[index];
  }


  void setUserId(String userId) {
    _userId = userId;
    _loadHistory();
  }


  // --------------------------
  // Persistence
  // --------------------------
  Future<void> _saveHistory() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'feedback_$_userId';
    final jsonList = _history.map((e) => e.toJson()).toList();
    await prefs.setStringList(key, jsonList);
  }

  Future<void> _loadHistory() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'feedback_$_userId';
    final jsonList = prefs.getStringList(key) ?? [];
    _history
      ..clear()
      ..addAll(jsonList.map((s) => FeedbackItem.fromJson(s)));
    notifyListeners();
  }
}
class FeedbackItem {
  final int score;
  final bool correct;
  final String transcript;
  final DateTime timestamp;

  FeedbackItem({
    required this.score,
    required this.correct,
    required this.transcript,
    required this.timestamp,
  });

  // Serialization helpers
  Map<String, dynamic> toMap() => {
    'score': score,
    'correct': correct,
    'transcript': transcript,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FeedbackItem.fromMap(Map<String, dynamic> map) => FeedbackItem(
    score: map['score'],
    correct: map['correct'],
    transcript: map['transcript'],
    timestamp: DateTime.parse(map['timestamp']),
  );

  String toJson() => json.encode(toMap());

  factory FeedbackItem.fromJson(String jsonStr) =>
      FeedbackItem.fromMap(json.decode(jsonStr));
}


