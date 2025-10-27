// FILE: lib/screens/word_lists_screen.dart
// PURPOSE: Select a word list and browse words in that list.
// TOOLS: Flutter core; provider (watch WordListModel).
// RELATIONSHIPS: Reads WordListModel.selectedList and .words; (future) sets targets in PracticeModel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_list_model.dart';
import '../models/practice_model.dart';
import '../widgets/word_card.dart';

class WordListsScreen extends StatelessWidget {
  const WordListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WordListModel>();
    final lists = model.lists;
    final words = model.wordsInSelected;

    return Scaffold(
      appBar: AppBar(title: const Text('Word Lists')),
      body: Column(
        children: [
          if (lists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No lists found. Check assets/seed_words.csv in pubspec.yaml.'),
            ),
          if (lists.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: lists.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final list = lists[i];
                  final selected = list == model.selectedList;
                  return ChoiceChip(
                    label: Text(list),
                    selected: selected,
                    onSelected: (_) => context.read<WordListModel>().selectList(list),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: words.length,
              itemBuilder: (_, i) {
                final w = words[i];
                return InkWell(
                  onTap: () {
                    context.read<PracticeModel>().setTarget(w);
                    ScaffoldMessenger.of(_).showSnackBar(
                      SnackBar(content: Text('Selected "${w.word}" for practice')),
                    );
                  },
                  child: WordCard(word: w.word, sentence: w.sentence),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
