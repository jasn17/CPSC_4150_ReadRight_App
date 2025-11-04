// PURPOSE: Compare recognized text to target word and produce a score, with homophone handling.

import 'dart:math';

class ScoringService {
  // Map homophones / common numeral confusions to canonical words
  static final Map<String, List<String>> _homophones = {
    'to': ['to', 'too', 'two', '2',],
    'for': ['for', 'four', 'fore', '4'],
    'be': ['be', 'bee', 'b'],
    'see': ['see', 'sea', 'c'],
    'you': ['you', 'u'],
    'are': ['are', 'r'],
    'why': ['why', 'y'],
    'oh': ['oh', 'o', '0'],
  };

  /// Normalizes a word to its canonical form if it matches a homophone group
  static String _normalizeWord(String word) {
    final w = word.trim().toLowerCase();
    for (final entry in _homophones.entries) {
      if (entry.value.contains(w)) return entry.key;
    }
    return w;
  }

  /// Computes similarity score 0–100 between spoken and target words
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
