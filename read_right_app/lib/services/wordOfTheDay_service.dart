import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/word_list_model.dart';

class WordOfTheDayService {
  static const _wordKey = 'word_of_the_day';
  static const _dateKey = 'word_of_the_day_date';

  final WordListModel wordListModel;

  WordOfTheDayService(this.wordListModel);

  /// Returns the Word of the Day, updating automatically if it's a new day.
  Future<WordItem?> getWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final storedWord = prefs.getString(_wordKey);
    final storedDate = prefs.getString(_dateKey);

    final now = DateTime.now();
    final todayString = '${now.year}-${now.month}-${now.day}'; // e.g., "2025-11-29"

    if (storedWord != null && storedDate == todayString) {
      // Same day → return stored word
      return wordListModel.allWords.firstWhere(
            (w) => w.word == storedWord,
        orElse: () => _pickNewWord(prefs, todayString),
      );
    }

    // New day → pick a new word
    return _pickNewWord(prefs, todayString);
  }

  WordItem _pickNewWord(SharedPreferences prefs, String dateString) {
    final random = Random();
    final newWord = wordListModel.allWords[random.nextInt(wordListModel.allWords.length)];

    prefs.setString(_wordKey, newWord.word);
    prefs.setString(_dateKey, dateString);

    return newWord;
  }
}
