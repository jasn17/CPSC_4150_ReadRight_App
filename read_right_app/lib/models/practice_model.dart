import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/speech_service.dart';
import '../services/scoring_service.dart';
import '../services/sync_service.dart';
import '../models/word_list_model.dart';
import '../models/practice_attempt.dart';
import 'package:uuid/uuid.dart';

class PracticeResult {
  final String transcript;
  final int score; // 0-100
  final bool correct;

  PracticeResult({
    required this.transcript,
    required this.score,
    required this.correct,
  });
}

class PracticeModel extends ChangeNotifier {
  WordItem? _target;
  PracticeResult? _last;
  bool _isRecording = false;
  bool _isCardMode = false;
  String? _userId; // Current user ID

  WordItem? get target => _target;
  PracticeResult? get lastResult => _last;
  bool get isRecording => _isRecording;
  bool get isCardMode => _isCardMode;

  final SpeechService _speech = SpeechService();
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  Map<String, Set<String>> masteredWordsByList = {}; // list -> set of mastered words
  int currentWordIndex = 0;

  // Constructor now requires SyncService
  PracticeModel(this._syncService);

  /// Set the current user ID
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Public setter for target
  void setTarget(WordItem item) {
    _target = item;
    _last = null;
    notifyListeners();
  }

  /// Reset last result
  void reset() {
    _last = null;
    notifyListeners();
  }

  void setCardMode(bool cardMode) {
    _isCardMode = cardMode;
    notifyListeners();
  }

  void toggleMode() {
    _isCardMode = !_isCardMode;
    notifyListeners();
  }

  /// Speak a word using TTS
  Future<void> speakWord(String word) async {
    await _speech.speak(word);
  }

  /// Initialize from WordListModel and persisted data
  Future<void> init(WordListModel wordListModel, String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    masteredWordsByList[wordListModel.selectedList ?? 'Dolch'] =
        prefs.getStringList('mastered_${wordListModel.selectedList}')?.toSet() ?? {};

    _advanceToNextWord(wordListModel);
  }

  void _advanceToNextWord(WordListModel wordListModel) {
    final words = wordListModel.wordsInSelected;
    final mastered = masteredWordsByList[wordListModel.selectedList] ?? {};

    for (int i = currentWordIndex; i < words.length; i++) {
      if (!mastered.contains(words[i].word)) {
        _target = words[i];
        currentWordIndex = i;
        _last = null;
        notifyListeners();
        return;
      }
    }

    // All mastered: stay at last word
    if (words.isNotEmpty) _target = words.last;
    notifyListeners();
  }

  /// Handle answer after recording, with optional cloud pronunciation assessment
  /// 
  /// If audioBytes provided, tries Azure cloud assessment first
  /// Falls back to local Levenshtein if cloud unavailable
  Future<void> handleAnswer(
    String transcript,
    WordListModel wordListModel, {
    List<int>? audioBytes,
  }) async {
    if (_target == null || _userId == null) return;

    int score;

    // If we have audio bytes, try cloud assessment
    if (audioBytes != null && audioBytes.isNotEmpty) {
      final cloudAssessment = await ScoringService.assessWithCloudFallback(
        audioBytes: audioBytes,
        targetWord: _target!.word,
        userId: _userId,
      );
      score = cloudAssessment.score;

      // If cloud unavailable (score == 0), fall back to local transcript scoring
      if (score == 0 && transcript.isNotEmpty) {
        score = ScoringService.computeScore(transcript, _target!.word);
      }
    } else {
      // No audio bytes - use local transcript scoring only
      score = ScoringService.computeScore(transcript, _target!.word);
    }

    final correct = score > 80;

    _last = PracticeResult(transcript: transcript, score: score, correct: correct);

    // Create practice attempt record
    final attempt = PracticeAttempt(
      id: _uuid.v4(),
      userId: _userId!,
      wordList: wordListModel.selectedList ?? 'Dolch',
      targetWord: _target!.word,
      transcript: transcript,
      score: score,
      correct: correct,
      timestamp: DateTime.now(),
      synced: false,
    );

    // Save to local DB and queue for sync
    await _syncService.saveAttempt(attempt);

    // Mark mastered if correct
    if (correct) {
      final list = wordListModel.selectedList!;
      masteredWordsByList[list] ??= {};
      masteredWordsByList[list]!.add(_target!.word);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('mastered_$list', masteredWordsByList[list]!.toList());
    }

    notifyListeners();

    // Speak word + sentence
    await _speech.speak(_target!.word);
    await Future.delayed(const Duration(milliseconds: 500));
    await _speech.speak(_target!.sentence);

    // Auto-advance to next word after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      currentWordIndex++;
      _advanceToNextWord(wordListModel);
    });
  }

  Future<void> startRecording(WordListModel wordListModel) async {
    if (_isRecording || _target == null) return;

    _isRecording = true;
    notifyListeners();

    try {
      await _speech.stopListening();
      final result = await _speech.recordOnce(timeoutSeconds: 5);
      
      // Pass both transcript and audio bytes if available
      await handleAnswer(
        result?.text ?? '',
        wordListModel,
        audioBytes: result?.audioBytes,
      );
    } catch (e) {
      await handleAnswer('', wordListModel);
    } finally {
      _isRecording = false;
      notifyListeners();
    }
  }

  /// Count how many words mastered in the current list
  int masteredCount(String list) => masteredWordsByList[list]?.length ?? 0;
}