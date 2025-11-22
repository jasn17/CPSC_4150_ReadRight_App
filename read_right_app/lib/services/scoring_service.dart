// PURPOSE: Compare recognized text to target word and produce a score, with cloud Azure support and local fallback

import 'dart:math';
import 'azure_pronunciation_service.dart';

class ScoringService {
  // Map homophones / common numeral confusions to canonical words
  static final Map<String, List<String>> _homophones = {
    'to': [
      'to',
      'too',
      'two',
      '2',
    ],
    'for': ['for', 'four', 'fore', '4'],
    'be': ['be', 'bee', 'b'],
    'see': ['see', 'sea', 'c'],
    'you': ['you', 'u'],
    'are': ['are', 'r'],
    'why': ['why', 'y'],
    'oh': ['oh', 'o', '0'],
  };

  // Azure pronunciation service instance
  static final AzurePronunciationService _azureService =
      AzurePronunciationService(
    serverBaseUrl:
        'http://localhost:5000', // Configure with your backend URL in main.dart
  );

  /// Normalizes a word to its canonical form if it matches a homophone group
  static String _normalizeWord(String word) {
    final w = word.trim().toLowerCase();
    for (final entry in _homophones.entries) {
      if (entry.value.contains(w)) return entry.key;
    }
    return w;
  }

  /// Computes similarity score 0–100 between spoken and target words (LOCAL ONLY)
  /// This is the fallback method used when cloud service is unavailable
  static int computeScore(String spoken, String target) {
    spoken = _normalizeWord(spoken);
    target = _normalizeWord(target);

    if (spoken.isEmpty) return 0;
    if (spoken == target) return 100;

    final dist = _levenshtein(spoken, target);
    final maxLen = max(spoken.length, target.length);
    final similarity = (1 - dist / maxLen);
    return (similarity * 100).clamp(0, 100).round();
  }

  /// Assess pronunciation using Azure cloud service with local fallback
  ///
  /// Tries Azure pronunciation assessment first for accurate phoneme analysis,
  /// falls back to local Levenshtein if cloud unavailable (network issue, timeout, etc)
  ///
  /// [audioBytes] - Raw WAV audio from microphone recording
  /// [targetWord] - The word being pronounced (reference text for Azure)
  /// [userId] - Optional user ID for server-side tracking
  ///
  /// Returns:
  /// - score (0-100): pronunciation quality score
  /// - details: full assessment data if available (null if using local fallback)
  /// - usedCloud: true if Azure was used, false if local fallback
  static Future<({int score, Map<String, dynamic>? details, bool usedCloud})>
      assessWithCloudFallback({
    required List<int> audioBytes,
    required String targetWord,
    String? userId,
  }) async {
    try {
      // Try cloud assessment first (more accurate, phoneme-level scoring)
      final cloudScore = await _azureService.assessPronunciation(
        audioData: audioBytes,
        referenceText: targetWord,
        userId: userId,
      );

      return (
        score: cloudScore.simpleScore,
        details: cloudScore.toJson(),
        usedCloud: true,
      );
    } catch (e) {
      print('Cloud assessment failed ($e), using local fallback');
      // Cloud service unavailable - we cannot proceed without audio transcript
      // In a real scenario, would run local STT on the audio first
      return (
        score: 0, // Indicate assessment incomplete
        details: {
          'error': 'Cloud service unavailable',
          'exception': e.toString()
        },
        usedCloud: false,
      );
    }
  }

  /// Check if cloud service is available before attempting assessment
  /// Useful for showing appropriate UI (cloud vs local mode)
  static Future<bool> isCloudServiceAvailable() async {
    try {
      return await _azureService.isServerAvailable();
    } catch (_) {
      return false;
    }
  }

  // Standard Levenshtein distance
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(min);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
