// FILE: lib/models/practice_attempt.dart
// PURPOSE: Data model for a single practice attempt that can be stored and synced

class PracticeAttempt {
  final String id; // Unique identifier
  final String userId; // Student user ID
  final String wordList; // e.g., "Dolch", "Phonics-CVC"
  final String targetWord; // Word they were practicing
  final String transcript; // What was recognized
  final int score; // 0-100
  final bool correct; // Did they pass?
  final DateTime timestamp; // When this happened
  final bool synced; // Has this been synced to cloud?

  PracticeAttempt({
    required this.id,
    required this.userId,
    required this.wordList,
    required this.targetWord,
    required this.transcript,
    required this.score,
    required this.correct,
    required this.timestamp,
    this.synced = false,
  });

  // Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'wordList': wordList,
      'targetWord': targetWord,
      'transcript': transcript,
      'score': score,
      'correct': correct ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  // Create from SQLite Map
  factory PracticeAttempt.fromMap(Map<String, dynamic> map) {
    return PracticeAttempt(
      id: map['id'] as String,
      userId: map['userId'] as String,
      wordList: map['wordList'] as String,
      targetWord: map['targetWord'] as String,
      transcript: map['transcript'] as String,
      score: map['score'] as int,
      correct: map['correct'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      synced: map['synced'] == 1,
    );
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'wordList': wordList,
      'targetWord': targetWord,
      'transcript': transcript,
      'score': score,
      'correct': correct,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  PracticeAttempt copyWith({
    String? id,
    String? userId,
    String? wordList,
    String? targetWord,
    String? transcript,
    int? score,
    bool? correct,
    DateTime? timestamp,
    bool? synced,
  }) {
    return PracticeAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wordList: wordList ?? this.wordList,
      targetWord: targetWord ?? this.targetWord,
      transcript: transcript ?? this.transcript,
      score: score ?? this.score,
      correct: correct ?? this.correct,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }
}