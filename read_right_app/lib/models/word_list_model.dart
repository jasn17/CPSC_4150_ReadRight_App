// FILE: lib/models/word_list_model.dart
// PURPOSE: Manages available lists, current selection, and word items (skeleton seed).
// TOOLS: ChangeNotifier.
// RELATIONSHIPS: Read by word_lists_screen.dart; later backed by data/words_repository.dart (CSV/SQLite).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class WordItem {
  final String list;      // e.g., Dolch1, Phonics-CVC
  final String word;      // e.g., cat
  final String sentence;  // optional sample sentence

  WordItem({required this.list, required this.word, required this.sentence});
}

class WordListModel extends ChangeNotifier {
  final Map<String, List<WordItem>> _byList = {};
  String? _selectedList;
  WordItem? _currentTarget;

  List<String> get lists => _byList.keys.toList()..sort();
  String? get selectedList => _selectedList;
  List<WordItem> get wordsInSelected =>
      _selectedList == null ? [] : (_byList[_selectedList] ?? []);
  WordItem? get currentTarget => _currentTarget;

  Future<void> loadFromAssets({
    String path = 'assets/seed_words_with_sentences_complete.csv', // ✅ use your real file
  }) async {
    final csv = await rootBundle.loadString(path);
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return;

    final header = lines.first.toLowerCase();
    final isWordSentenceFormat = header.startsWith('word');

    final dataLines = (header.contains('word') || header.contains('list,word'))
        ? lines.skip(1)
        : lines;

    for (final line in dataLines) {
      if (line.trim().isEmpty) continue;
      final parts = _safeSplitCsv(line);
      if (parts.isEmpty) continue;

      late final String list;
      late final String word;
      late final String sentence;

      if (isWordSentenceFormat) {
        // Handles "Word,Sentence 1,Sentence 2"
        list = 'Dolch'; // default list name
        word = (parts.length > 0 ? parts[0] : '').trim();
        sentence = [
          if (parts.length > 1) parts[1].trim(),
          if (parts.length > 2) parts[2].trim(),
        ].where((s) => s.isNotEmpty).join(' ');
      } else {
        // Handles "list,word,sentence"
        list = (parts.length > 0 ? parts[0] : 'Default').trim();
        word = (parts.length > 1 ? parts[1] : '').trim();
        sentence = (parts.length > 2 ? parts[2] : '').trim();
      }

      if (word.isEmpty) continue;

      final wi = WordItem(list: list, word: word, sentence: sentence);
      _byList.putIfAbsent(list, () => []).add(wi);
    }

    _selectedList ??= lists.isNotEmpty ? lists.first : null;
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

  // Tiny CSV splitter that respects a single pair of quotes around sentence.
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
