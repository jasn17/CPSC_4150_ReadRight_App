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

  List<String> get lists => _byList.keys.toList()..sort(_naturalSort);
  String? get selectedList => _selectedList;
  List<WordItem> get wordsInSelected =>
      _selectedList == null ? [] : (_byList[_selectedList] ?? []);
  WordItem? get currentTarget => _currentTarget;

  // Returns the words for a specific list without changing selection.
  List<WordItem> wordsFor(String list) => _byList[list] ?? [];

  Future<void> loadFromAssets({String path = 'assets/seed_words.csv'}) async {
    final csv = await rootBundle.loadString(path);
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return;

    // Detect format. If header looks like "list,word,sentence" use simple parser.
    final hasSimpleHeader = lines.first.toLowerCase().contains('list,word');
    if (hasSimpleHeader) {
      final dataLines = lines.skip(1);
      for (final line in dataLines) {
        if (line.trim().isEmpty) continue;
        final parts = _safeSplitCsv(line);
        if (parts.isEmpty) continue;
        final list = (parts.isNotEmpty ? parts[0] : 'Default').trim();
        final word = (parts.length > 1 ? parts[1] : '').trim();
        final sentence = (parts.length > 2 ? parts[2] : '').trim();
        if (word.isEmpty) continue;
        _byList.putIfAbsent(list, () => []).add(WordItem(list: list, word: word, sentence: sentence));
      }
    } else {
      // Parse seed_words.csv format where lines like ",LIST N,..." mark section starts
      String? currentList;
      for (final rawLine in lines) {
        final line = rawLine.trimRight();
        if (line.isEmpty) continue;
        final parts = _safeSplitCsv(line);
        if (parts.isEmpty) continue;

        // Identify a list marker in any column (commonly column 1)
        final markerIndex = parts.indexWhere((p) => p.trim().toUpperCase().startsWith('LIST '));
        if (markerIndex != -1) {
          // Normalize title like "LIST 1" → "List 1"
          final title = parts[markerIndex].trim();
          currentList = title.substring(0, 1).toUpperCase() + title.substring(1).toLowerCase();
          _byList.putIfAbsent(currentList, () => []);
          continue;
        }

        // If inside a list, collect non-empty tokens from all columns as words
        if (currentList != null) {
          for (final token in parts.map((p) => p.trim())) {
            if (token.isEmpty) continue;
            if (_isSectionToken(token)) continue; // skip markers like vowels or headers
            // Add as a word with no sentence
            _byList.putIfAbsent(currentList, () => []).add(
              WordItem(list: currentList, word: token, sentence: ''),
            );
          }
        }
      }
    }

    // Select the first list by default
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
    // Sort "List 1", "List 2", ... numerically if possible, else lexicographically
    int? numA;
    int? numB;
    final ra = RegExp(r'\d+').firstMatch(a);
    final rb = RegExp(r'\d+').firstMatch(b);
    if (ra != null) numA = int.tryParse(ra.group(0)!);
    if (rb != null) numB = int.tryParse(rb.group(0)!);
    if (numA != null && numB != null) return numA.compareTo(numB);
    return a.compareTo(b);
  }
}
