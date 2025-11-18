import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/speech_service.dart';
import '../services/scoring_service.dart';
import 'word_list_model.dart';

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

  WordItem? get target => _target;
  PracticeResult? get lastResult => _last;
  bool get isRecording => _isRecording;
  bool get isCardMode => _isCardMode;

  final SpeechService _speech = SpeechService();

  Map<String, Set<String>> masteredWordsByList =
      {}; // list -> set of mastered words
  int currentWordIndex = 0;

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

  /// Initialize from WordListModel and persisted data
  Future<void> init(WordListModel wordListModel) async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure we have a selected list
    final selectedList = wordListModel.selectedList ?? 'Dolch';

    // Load mastered words for the current list
    masteredWordsByList[selectedList] =
        prefs.getStringList('mastered_$selectedList')?.toSet() ?? {};

    // Set the first unmastered word as target
    _advanceToNextWord(wordListModel);

    notifyListeners();
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

  /// Handle answer after recording
  Future<void> handleAnswer(
      String transcript, WordListModel wordListModel) async {
    if (_target == null) return;

    final score = ScoringService.computeScore(transcript, _target!.word);
    final correct = score > 80;

    _last =
        PracticeResult(transcript: transcript, score: score, correct: correct);

    // Mark mastered if correct
    if (correct) {
      final list = wordListModel.selectedList!;
      masteredWordsByList[list] ??= {};
      masteredWordsByList[list]!.add(_target!.word);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'mastered_$list', masteredWordsByList[list]!.toList());
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
      final transcript = await _speech.recordOnce(timeoutSeconds: 7);

      await handleAnswer(transcript ?? '', wordListModel);
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
