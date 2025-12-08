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

  // Dolch level lookup tables
  static const Set<String> dolchPreK = {
    "a","and","away","big","blue","can","come","down","find","for","funny","go","help",
    "here","I","in","is","it","jump","little","look","make","me","my","not","one","play",
    "red","run","said","see","the","three","to","two","up","we","where","yellow","you"
  }; // all good

  static const Set<String> dolchK = {
    "all","am","are","at","ate","be","black","brown","but","came","did","do","eat","four",
    "get","good","have","he","into","like","must","new","no","now","on","our","out","please",
    "pretty","ran","ride","saw","say","she","so","soon","that","there","they","this","too",
    "under","want","was","well","went","what","white","who","will","with","yes"
  }; //all good

  static const Set<String> dolch1 = {
    "after","again","an","any","as","ask","by","could","every","fly","from","give","going",
    "had","has","her","him","his","how","just","know","let","live","may","of","old","once",
    "open","over","put","round","some","stop","take","thank","them","then","think","walk",
    "were","when"
  }; // all good

  static const Set<String> dolch2 = {
    "always","around","because","been","before","best","both","buy","call","cold","does",
    "don’t","fast","first","five","found","gave","goes","green","its","made","many","off",
    "or","pull","read","right","sing","sit","sleep","tell","their","these","those","upon",
    "us","use","very","wash","which","why","wish","work","would","write","your"
  };

  static const Set<String> dolch3 = {
    "about","better","bring","carry","clean","cut","done","draw","drink","eight","fall",
    "far","full","got","grow","hold","hot","hurt","if","keep","kind","laugh","light","long",
    "much","myself","never","only","own","pick","seven","shall","show","six","small","start",
    "ten","today","together","try","warm"
  };

  final List<WordItem> _allWords = [];
  String? _selectedList;
  WordItem? _currentTarget;
  int _currentCardIndex = 0;

  List<String> get lists => _byList.keys.toList()..sort(_naturalSort);
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
        // Determine Dolch level by word lookup
        word = (parts.isNotEmpty ? parts[0] : '').trim();
        sentence1 = (parts.length > 1 ? parts[1] : '').trim();
        sentence2 = (parts.length > 2 ? parts[2] : '').trim();
        sentence = [sentence1, sentence2].where((s) => s.isNotEmpty).join(' ');

        final lower = word.toLowerCase();

        if (dolchPreK.contains(lower)) {
          list = "Dolch-PreK";
        } else if (dolchK.contains(lower)) {
          list = "Dolch-K";
        } else if (dolch1.contains(lower)) {
          list = "Dolch-1";
        } else if (dolch2.contains(lower)) {
          list = "Dolch-2";
        } else if (dolch3.contains(lower)) {
          list = "Dolch-3";
        } else {
          continue;
        }
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

  bool _isSectionToken(String s) {
    final u = s.toUpperCase();
    if (u.startsWith('LIST ')) return true;
    // Skip single vowel markers often present in the CSV
    if (u.length == 1 && {'A', 'E', 'I', 'O', 'U'}.contains(u)) return true;
    // Skip known headers
    if ({'DOLCH', 'PHONICS BASIC', 'PHONICS/MINIMAL PAIRS'}.contains(u)) return true;
    return false;
  }

  int _naturalSort(String a, String b) {
    const dolchOrder = {
      "dolch-prek": 0,
      "dolch-k": 1,
      "dolch-1": 2,
      "dolch-2": 3,
      "dolch-3": 4,
    };

    final al = a.toLowerCase();
    final bl = b.toLowerCase();

    final ai = dolchOrder[al];
    final bi = dolchOrder[bl];

    // If both are dolch levels, sort by defined order
    if (ai != null && bi != null) return ai.compareTo(bi);

    // Dolch lists always come before non-Dolch lists
    if (ai != null) return -1;
    if (bi != null) return 1;

    // Otherwise fallback to normal lexicographic sort
    return a.compareTo(b);
  }

}
