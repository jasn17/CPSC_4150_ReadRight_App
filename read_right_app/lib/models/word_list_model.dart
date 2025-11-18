import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class WordItem {
  final String list; // e.g., Dolch1, Phonics-CVC
  final String word; // e.g., cat
  final String sentence; // optional sample sentence
  final String sentence1; // first sentence
  final String sentence2; // second sentence

  WordItem({
    required this.list,
    required this.word,
    required this.sentence,
    required this.sentence1,
    required this.sentence2,
  });
}

class WordListModel extends ChangeNotifier {
  final Map<String, List<WordItem>> _byList = {};
  final List<WordItem> _allWords = [];
  String? _selectedList;
  WordItem? _currentTarget;
  int _currentCardIndex = 0;

  List<String> get lists => _byList.keys.toList()..sort();
  String? get selectedList => _selectedList;
  List<WordItem> get wordsInSelected => _selectedList == null ? [] : (_byList[_selectedList] ?? []);
  WordItem? get currentTarget => _currentTarget;
  List<WordItem> get allWords => _allWords;
  int get currentCardIndex => _currentCardIndex;
  WordItem? get currentCard => _allWords.isNotEmpty ? _allWords[_currentCardIndex] : null;

  Future<void> loadFromAssets({
    String path = 'assets/seed_words_with_sentences_complete.csv',
  }) async {
    final csv = await rootBundle.loadString(path);
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return;

    final header = lines.first.toLowerCase();
    final isWordSentenceFormat = header.startsWith('word');
    final dataLines = (header.contains('word') || header.contains('list,word')) ? lines.skip(1) : lines;

    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final parts = _safeSplitCsv(line);
      if (parts.isEmpty) continue;

      late final String list;
      late final String word;
      late final String sentence;
      late final String sentence1;
      late final String sentence2;

      if (isWordSentenceFormat) {
        list = 'Dolch';
        word = (parts.length > 0 ? parts[0] : '').trim();
        sentence1 = (parts.length > 1 ? parts[1] : '').trim();
        sentence2 = (parts.length > 2 ? parts[2] : '').trim();
        sentence = [sentence1, sentence2].where((s) => s.isNotEmpty).join(' ');
      } else {
        list = (parts.length > 0 ? parts[0] : 'Default').trim();
        word = (parts.length > 1 ? parts[1] : '').trim();
        sentence = (parts.length > 2 ? parts[2] : '').trim();
        sentence1 = sentence;
        sentence2 = '';
      }
      if (word.isEmpty) continue;

      final wi = WordItem(
        list: list,
        word: word,
        sentence: sentence,
        sentence1: sentence1,
        sentence2: sentence2,
      );

      _byList.putIfAbsent(list, () => []).add(wi);
      _allWords.add(wi);
    }

    // Default to Dolch if present
    _selectedList = _byList.containsKey('Dolch') ? 'Dolch' : (lists.isNotEmpty ? lists.first : null);
    notifyListeners();
  }

  void selectList(String list) {
    _selectedList = list;
    notifyListeners();
  }

  void chooseTarget(WordItem item) {
    _currentTarget = item;
    notifyListeners();
  }

  // Card navigation
  void nextCard() {
    if (_allWords.isNotEmpty) {
      _currentCardIndex = (_currentCardIndex + 1) % _allWords.length;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_allWords.isNotEmpty) {
      _currentCardIndex = (_currentCardIndex - 1) % _allWords.length;
      if (_currentCardIndex < 0) _currentCardIndex = _allWords.length - 1;
      notifyListeners();
    }
  }

  void resetCardIndex() {
    _currentCardIndex = 0;
    notifyListeners();
  }

  // CSV splitter
  List<String> _safeSplitCsv(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    out.add(buf.toString());
    return out;
  }
}
