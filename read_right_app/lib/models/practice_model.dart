import 'package:flutter/foundation.dart';
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

  void setTarget(WordItem item) {
    _target = item;
    _last = null;
    notifyListeners();
  }

  /// Auto-initialize target from the selected list
  void initFromWordListModel(WordListModel wordListModel) {
    if (_target == null && wordListModel.selectedList != null) {
      final words = wordListModel.wordsInSelected;
      if (words.isNotEmpty) {
        _target = words.first;
        _last = null;
        notifyListeners();
      }
    }
  }

  Future<void> startRecording() async {
    if (_isRecording || _target == null) return;

    _isRecording = true;
    notifyListeners();

    try {
      await _speech.stop();
      final transcript = await _speech.recordOnce(timeoutSeconds: 7);

      if (transcript == null || transcript.trim().isEmpty) {
        _last = PracticeResult(transcript: '', score: 0, correct: false);
      } else {
        final score = ScoringService.computeScore(transcript, _target!.word);
        final correct = score > 80;
        _last = PracticeResult(
          transcript: transcript,
          score: score,
          correct: correct,
        );
      }
    } catch (e) {
      _last = PracticeResult(transcript: '', score: 0, correct: false);
    } finally {
      _isRecording = false;
      notifyListeners();
    }
  }

  void stopRecording() async {
    await _speech.stop();
    _isRecording = false;
    notifyListeners();
  }

  void reset() {
    _last = null;
    notifyListeners();
  }

  void toggleMode() {
    _isCardMode = !_isCardMode;
    notifyListeners();
  }

  void setCardMode(bool cardMode) {
    _isCardMode = cardMode;
    notifyListeners();
  }
}
